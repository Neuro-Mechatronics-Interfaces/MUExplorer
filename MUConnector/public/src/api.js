export async function sendCmd(body) {
  const res = await fetch('http://127.0.0.1:55556/send', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(body)
  });
  return res.json();
}

export async function fetchConfig() {
  const res = await fetch('http://127.0.0.1:55556/config', {
    method: 'GET', 
    headers: {'Accept': 'application/json'}, 
  });
  return res.json();
}

export async function waitAck(txid, timeoutMs = 15000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort('timeout'), timeoutMs);
  try {
    const r = await fetch(`http://127.0.0.1:55556/wait-ack?txid=${encodeURIComponent(txid)}`, {
      method: 'GET',
      signal: ctrl.signal,
      headers: { 'Accept': 'application/json' }
    });
    clearTimeout(t);
    if (!r.ok) {
      const e = await r.json().catch(() => ({}));
      throw new Error(e.error || `HTTP ${r.status}`);
    }
    return await r.json(); // { ok, ack }
  } finally {
    clearTimeout(t);
  }
}