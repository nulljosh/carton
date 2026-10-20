// The Carton web app: a list of UPS numbers in localStorage, each read through /api/track.
const KEY = "carton.parcels";
const $ = (id) => document.getElementById(id);
const parseNumber = (t) => (t.match(/1Z[0-9A-Za-z]{16}/) || [])[0]?.toUpperCase() || null;

let parcels = [];
try { parcels = JSON.parse(localStorage.getItem(KEY) || "[]"); } catch {}
const save = () => { try { localStorage.setItem(KEY, JSON.stringify(parcels)); } catch {} };
const state = {};  // number -> { status } | { error } | "loading"

function daysLeft(iso) {
  if (!iso) return null;
  const [y, m, d] = iso.split("-").map(Number);
  const t = new Date(); t.setHours(0, 0, 0, 0);
  return Math.round((new Date(y, m - 1, d) - t) / 86400000);
}

function row(n) {
  const s = state[n];
  const li = document.createElement("li");
  const meta = document.createElement("div"); meta.className = "meta";
  const num = document.createElement("div"); num.className = "num"; num.textContent = n;
  const sub = document.createElement("div"); sub.className = "sub";
  meta.append(num, sub);
  li.append(meta);
  if (s === "loading" || !s) {
    sub.textContent = "Checking with UPS";
    const sp = document.createElement("div"); sp.className = "spin"; sp.setAttribute("aria-hidden", "true"); li.append(sp);
  } else if (s.error) {
    const a = document.createElement("a"); a.href = `https://www.ups.com/track?tracknum=${n}`; a.textContent = "Open on UPS"; a.target = "_blank"; a.rel = "noopener";
    sub.append(`${s.error} `, a);
  } else {
    sub.textContent = [s.status, s.lastLocation && `Last scan ${s.lastLocation.split(",").slice(0, 2).join(",")}`].filter(Boolean).join(" · ");
    const d = daysLeft(s.etaDate);
    const box = document.createElement("div"); box.className = "days";
    if (s.delivered) box.innerHTML = "<b>✓</b><span>delivered</span>";
    else if (d !== null) box.innerHTML = d <= 0 ? "<b>Today</b>" : `<b>${d}</b><span>${d === 1 ? "day" : "days"}</span>`;
    li.append(box);
  }
  const x = document.createElement("button"); x.className = "x"; x.textContent = "×"; x.setAttribute("aria-label", `Remove ${n}`);
  x.onclick = () => { parcels = parcels.filter((p) => p !== n); save(); render(); };
  li.append(x);
  return li;
}

function render() { $("list").replaceChildren(...parcels.map(row)); }

async function refresh(n) {
  state[n] = "loading"; render();
  try {
    const r = await fetch(`/api/track/${n}`);
    const j = await r.json();
    state[n] = r.ok ? j : { error: j.error || "UPS didn't answer." };
  } catch { state[n] = { error: "Can't reach Carton right now." }; }
  render();
}

$("add").onsubmit = (e) => {
  e.preventDefault();
  const n = parseNumber($("num").value);
  if (!n) { $("hint").textContent = "That doesn't look like a UPS tracking number. They start with 1Z."; return; }
  if (!parcels.includes(n)) { parcels.unshift(n); save(); }
  $("num").value = "";
  refresh(n);
};

// carton.jaybulb.com/#1Z... adds that package; the hash never leaves the browser
const fromHash = parseNumber(decodeURIComponent(location.hash));
if (fromHash && !parcels.includes(fromHash)) { parcels.unshift(fromHash); save(); }
if (fromHash) history.replaceState(null, "", location.pathname);
render();
parcels.forEach(refresh);
