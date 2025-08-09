const express = require('express');
const crypto = require('crypto');
const dgram = require('dgram');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const app = express();

// --- Basic middleware/static ---
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

let udp;

// --- Locate and load config.yaml (sibling of MUExplorer.m) ---
const CONFIG_PATH = path.resolve(__dirname, '../@MUExplorer/config.yaml');

function loadConfig() {
    try {
        const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
        const cfg = yaml.load(raw);

        // Expected keys:
        //   MUConnectorPort            (HTTP port for this Node server)
        //   MUExplorerPort             (UDP port that MATLAB listens on)
        //   InitialProcessingParameters (object with defaults for the form)

        if (!cfg || typeof cfg !== 'object') throw new Error('config is empty or invalid');

        // Allow ENV overrides if desired
        const connectorPort = Number(cfg.MUConnectorPort);
        const explorerPort = Number(cfg.MUExplorerPort);
        const connectorUdpPort = Number(cfg.MUConnectorUDP);

        return {
            connectorPort,
            connectorAddress: cfg.MUConnectorIP || "127.0.0.1",
            explorerPort,
            explorerAddress: cfg.MUExplorerIP || "127.0.0.1",
            connectorUdpPort,
            initialParams: cfg.InitialProcessingParameters || {},
            version: cfg.Version || 2.2
        };
    } catch (e) {
        console.error('[MUConnector] Failed to read config.yaml:', e.message);
        // Sensible fallbacks
        return {
            connectorPort: 55557,
            explorerPort: 55555,
            connectorUdpPort: 55556,
            explorerAddress: "127.0.0.1",
            connectorAddress: "127.0.0.1",
            version: 2.2,
            initialParams: {}
        };
    }
}

let lastPing = 0;
let pingTimer;
let CONFIG = loadConfig();
// --- Pending ACKs by txid ---
const waiters = new Map(); // txid -> { resolve, reject, timeout }

function startUdp() {
    if (udp) return; // already open
    console.log('[MUConnector] Starting UDP...');
    udp = dgram.createSocket('udp4');
    udp.on('message', (buf, rinfo) => {
        try {
            const msg = JSON.parse(buf.toString());
            if (msg.cmd === 'ping') {
                lastPing = Date.now();
                return;
            }
            console.log(`[MUConnector] UDP message from ${rinfo.address}:${rinfo.port}:`, msg);
            console.log(`[MUConnector] Current waiters:`, Array.from(waiters.keys()));
            if (msg.txid && waiters.has(msg.txid)) {
                waiters.get(msg.txid).resolve(msg);
                waiters.delete(msg.txid);
                console.log(`[MUConnector] Resolved waiter for txid ${msg.txid}`);
            } else {
                console.warn(`[MUConnector] No waiter for txid ${msg.txid}, ignoring`);
            }
        } catch (err) {
            console.warn('[MUConnector] Server-side handling error:', err);
        }
    });

    udp.bind(CONFIG.connectorUdpPort, CONFIG.connectorAddress, () => {
        console.log(`[MUConnector] UDP bound at ${CONFIG.connectorAddress}:${CONFIG.connectorUdpPort}`);
        lastPing = Date.now();
        pingTimer = setInterval(checkPingTimeout, 10000);
    });
}

function stopUdp() {
    if (!udp) return;
    console.log('[MUConnector] Closing UDP Socket...');
    clearInterval(pingTimer);
    udp.close(() => console.log('[MUConnector] UDP closed'));
    udp = null;
}

function checkPingTimeout() {
    const pingMsg = Buffer.from(JSON.stringify({ cmd: 'ping' }));
    udp.send(pingMsg, CONFIG.explorerPort, CONFIG.explorerAddress, (err) => {
        if (err) console.error('[MUConnector] Ping send error:', err);
    });
    if (Date.now() - lastPing > 30000) { // 30 s timeout
        console.log('[MUConnector] No ping from MATLAB, closing UDP');
        stopUdp();
    }
}

function reloadConfig() {
    console.log('[MUConnector] Reloading config.yaml...');
    CONFIG = loadConfig();
    console.log('[MUConnector] Reloaded. MUConnector=%d MUExplorer=%d', CONFIG.connectorPort, CONFIG.explorerPort);
}



// --- API: send payload to MATLAB via UDP ---
app.post('/send', (req, res) => {
    if (!udp) {
        startUdp();
    }
    try {
        const txid = crypto.randomUUID();
        const enriched = {
            ...req.body,
            txid,
            reply_host: CONFIG.connectorAddress,
            reply_port: CONFIG.connectorUdpPort
        };
        const payload = Buffer.from(JSON.stringify(enriched));
        console.log(`[MUConnector] Sending command to MATLAB: ${JSON.stringify(enriched)}`);
        // Send UDP to MATLAB
        udp.send(payload, CONFIG.explorerPort, CONFIG.explorerAddress, (err) => {
            if (err) {
                console.error('[MUConnector] UDP send error:', err);
                return res.status(500).json({ ok: false, error: String(err) });
            }
        });
        res.status(202).json({ ok: true, txid });
    } catch (e) {
        console.error(e);
        res.status(400).json({ ok: false, error: String(e) });
    }
});

// --- API: wait for ACK ---
app.get('/wait-ack', (req, res) => {
    const { txid } = req.query;
    if (!txid) {
        return res.status(404).json({ ok: false, error: 'Missing txid for waiter lookup!' });
    }
    const timeout = setTimeout(() => {
        if (waiters.has(txid)) {
            waiters.get(txid).reject('ACK timeout');
            waiters.delete(txid);
            console.warn(`[MUConnector] ACK timeout for txid ${txid}`);
        }
    }, 15000); // 15s timeout
    waiters.set(txid, {
        resolve: (msg) => { 
            clearTimeout(timeout); 
            res.json({ ok: true, txid, ack: msg }); 
            console.log(`[MUConnector] ACK resolved for txid ${txid}:`, msg);
        },
        reject: (err) => { 
            clearTimeout(timeout); 
            res.status(504).json({ ok: false, error: err }); 
            console.warn(`[MUConnector] ACK rejected for txid ${txid}:`, err);
        }
    });
});

// --- API: serve config-derived defaults to the UI ---
app.get('/config', (_req, res) => {
    res.json({
        ok: true,
        connectorPort: CONFIG.connectorPort,
        connectorAddress: CONFIG.connectorAddress,
        explorerPort: CONFIG.explorerPort,
        explorerAddress: CONFIG.explorerAddress,
        connectorUdpPort: CONFIG.connectorUdpPort,
        initialParams: CONFIG.initialParams,
        version: CONFIG.version
    });
});

app.get('/reload', (req, res) => {
    try {
        reloadConfig();
        return res.json({
            ok: true,
            connectorPort: CONFIG.connectorPort,
            connectorAddress: CONFIG.connectorAddress,
            explorerPort: CONFIG.explorerPort,
            explorerAddress: CONFIG.explorerAddress,
            connectorUdpPort: CONFIG.connectorUdpPort,
            initialParams: CONFIG.initialParams,
            version: CONFIG.version
        });
    } catch (e) {
        console.error(e);
        res.status(400).json({ ok: false, error: String(e) });
    }
});

app.get('/', (_req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Optional: hot-reload config on SIGHUP (or just restart node to pick up changes)
process.on('SIGHUP', () => {
    reloadConfig();
});

// --- Start server ---
app.listen(CONFIG.connectorPort, () => {
    console.log(`[MUConnector] Bridge listening on http://${CONFIG.connectorAddress}:${CONFIG.connectorPort}`);
    console.log(`[MUConnector] Forwarding UDP to MATLAB ${CONFIG.explorerAddress}:${CONFIG.explorerPort}`);
});
