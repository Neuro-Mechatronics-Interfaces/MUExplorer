import { sendCmd, fetchConfig, waitAck } from './src/api.js';
import { formToOptions, applyInitialParams } from './src/form.js';

const form = document.getElementById('paramForm');
const statusEl = document.getElementById('status');

function setStatus(msg) {
  statusEl.textContent = msg;
}

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const options = formToOptions(form);
  console.log('Submitting options:', options);
  try {
    setStatus('Sending…');
    const resp = await sendCmd({ cmd: 'set_params', options }); // now returns { ok, txid }
    if (!resp?.ok) {
      setStatus(`Error: ${resp?.error || 'send failed'}`);
      return;
    }
    setStatus('Processing…');
    const ack = await waitAck(resp.txid);
    setStatus(ack.ok ? '✓ Applied' : `Error: ${ack?.error || 'ACK failed'}`);
  } catch (err) {
    setStatus(`Error: ${err.message || String(err)}`);
  }
});

document.getElementById('reprocessBtn').addEventListener('click', async () => {
  try {
    setStatus('Updating…');
    const resp = await sendCmd({ cmd: 'reprocess' }); // now returns { ok, txid }
    if (!resp?.ok) {
      setStatus(`Error: ${resp?.error || 'send failed'}`);
      return;
    }
    const ack = await waitAck(resp.txid);
    setStatus(ack.ok ? '✓ Reprocessed' : `Error: ${ack?.error || 'ACK failed'}`);
  } catch (err) {
    setStatus(`Error: ${err.message || String(err)}`);
  }
});

// Bootstrap defaults from /config
(async function initFromConfig() {
  try {
    const cfg = await fetchConfig();
    if (cfg?.ok && cfg.initialParams) {
      applyInitialParams(cfg.initialParams);
    }
  } catch (e) {
    console.warn('Failed to fetch /config defaults:', e);
  }
})();
