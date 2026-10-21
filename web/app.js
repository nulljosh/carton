// The Cartons web app: a list of UPS numbers in localStorage, each read through /api/track.
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

// The hero map: the newest package's last scan, a dotted line to its destination, drawn over ground.svg.
// ground.svg is stylized, so places land through a straight fit on two anchors (Vancouver and Louisville).
const toMap = (lat, lon) => [Math.min(940, Math.max(20, 180 + (lon + 123.12) * 15.52)), Math.min(520, Math.max(20, 135 + (49.28 - lat) * 20.4))];
const PROVINCES = new Set(["BC", "AB", "SK", "MB", "ON", "QC", "NB", "NS", "PE", "NL", "YT", "NT", "NU"]);
const titleCase = (t) => t.toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());

// "HODGKINS, IL, United States" or "LANGLEY, BC CA" -> a point on the map, via Open-Meteo's free geocoder (cached)
async function locate(text) {
  const parts = text.split(",").map((p) => p.trim());
  const city = titleCase(parts[0]), region = (parts[1] || "").split(/\s+/)[0].toUpperCase();
  const country = PROVINCES.has(region) ? "CA" : "US", key = `carton.geo.${city},${region}`;
  try { const hit = localStorage.getItem(key); if (hit) return { label: `${city}, ${region}`, at: JSON.parse(hit) }; } catch {}
  try {
    const j = await (await fetch(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city)}&count=10&language=en`)).json();
    const g = (j.results || []).find((r) => r.country_code === country);
    if (!g) return null;
    const at = toMap(g.latitude, g.longitude);
    try { localStorage.setItem(key, JSON.stringify(at)); } catch {}
    return { label: `${city}, ${region}`, at };
  } catch { return null; }
}

function drawTrip(from, to, ride = false) {
  const [ax, ay] = from.at, [bx, by] = to.at, lift = Math.hypot(bx - ax, by - ay) * 0.3;
  const d = `M${ax.toFixed(1)} ${ay.toFixed(1)}Q${((ax + bx) / 2).toFixed(1)} ${(Math.min(ay, by) - lift).toFixed(1)} ${bx.toFixed(1)} ${by.toFixed(1)}`;
  $("trip-line").setAttribute("d", d);
  for (const [id, x, y] of [["trip-from", ax, ay], ["trip-to", bx, by], ["trip-pulse", bx, by]]) { $(id).setAttribute("cx", x); $(id).setAttribute("cy", y); }
  // labels hang under their dots: the line arcs upward, and near the screen edge a side label would be cut off
  for (const [id, p, x, y, other] of [["trip-from-l", from, ax, ay, bx], ["trip-to-l", to, bx, by, ax]]) {
    const el = $(id);
    el.textContent = p.label;
    const inward = x <= other ? "start" : "end";  // text runs toward the middle of the screen
    el.setAttribute("x", x + (inward === "start" ? -10 : 10)); el.setAttribute("y", y + 30); el.setAttribute("text-anchor", inward);
  }
  $("trip-from").style.display = $("trip-from-l").style.display = ax === bx && ay === by ? "none" : "";
  // pan the map so the trip sits mid-screen; on a phone that keeps both ends in view
  const ground = document.querySelector(".ground");
  if (ground && innerWidth < 600) {  // phones: size the map so the whole trip fits the screen
    const w = Math.min(1100, Math.max(600, innerWidth * 0.62 * 960 / Math.max(1, Math.abs(bx - ax))));
    ground.style.width = `${w.toFixed(0)}px`; ground.style.marginLeft = `${(-w / 2).toFixed(0)}px`;
  }
  if (ground) ground.style.translate = `${((480 - (ax + bx) / 2) / 960 * ground.offsetWidth).toFixed(0)}px 0`;
  const box = $("trip-box");
  box.style.offsetPath = `path("${d}")`;
  box.classList.toggle("ride", ride);
  box.style.offsetDistance = ride ? "" : "0%";  // a live package sits at its last scan
}

async function showTrip(s, who = "Your package") {
  if (!s?.shipTo) return;
  const [to, from] = await Promise.all([locate(s.shipTo), s.lastLocation && !s.delivered ? locate(s.lastLocation) : null]);
  if (!to) return;
  drawTrip(from || to, to);
  const d = daysLeft(s.etaDate);
  const when = s.delivered ? "delivered" : d === null ? s.status : d <= 0 ? "arriving today" : `${d} ${d === 1 ? "day" : "days"} out`;
  $("tripnote").textContent = `On the map: ${who}, ${to.label.split(",")[0]}, ${when}.`;
}

// until something is tracked, a sample box rides Louisville to Vancouver
drawTrip({ label: "Louisville, KY", at: toMap(38.25, -85.76) }, { label: "Vancouver, BC", at: toMap(49.28, -123.12) }, true);

function render() { $("list").replaceChildren(...parcels.map(row)); }

async function refresh(n) {
  state[n] = "loading"; render();
  try {
    const r = await fetch(`/api/track/${n}`);
    const j = await r.json();
    state[n] = r.ok ? j : { error: j.error || "UPS didn't answer." };
    if (r.ok && n === parcels[0]) showTrip(j);
  } catch { state[n] = { error: "Can't reach Cartons right now." }; }
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

// cartons.jaybulb.com/#1Z... adds that package; the hash never leaves the browser
const fromHash = parseNumber(decodeURIComponent(location.hash));
if (fromHash && !parcels.includes(fromHash)) { parcels.unshift(fromHash); save(); }
if (fromHash) history.replaceState(null, "", location.pathname);
render();
parcels.forEach(refresh);
