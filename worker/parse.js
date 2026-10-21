// UPS tracking page text -> status. JS twin of UPSPage.parse in the app; keep the two in step.
// node worker/parse.test.mjs checks it against the same captured page text as tests/ParseCheck.swift.
const HEADLINES = ["delivered", "out for delivery", "on the way", "we have your package", "label created",
  "delivery attempted", "exception", "delayed", "returned to sender", "returning to sender", "held",
  "ready for pickup", "in transit"];
const DATE_LABELS = ["estimated delivery", "scheduled delivery", "delivered on", "delivery date", "delivered"];

export const isNotFound = (text) => /could not locate the shipment|tracking number is invalid|unable to find/i.test(text);

export function parse(text, number) {
  // UPS's icons render as words in the text (check_circle, chevron_right, help): drop them first
  const ICONS = new Set(["help", "close", "check", "lock", "info", "search", "menu"]);
  const lines = text.split("\n").map((l) => l.replace(/\b[a-z]+(?:_[a-z]+)+\b/g, "").trim()).filter((l) => l && !ICONS.has(l));
  const lower = lines.map((l) => l.toLowerCase());
  const squash = (s) => s.replace(/ /g, "").toUpperCase();
  if (!lines.some((l) => squash(l) === squash(number))) return null;
  if (!lower.some((l) => DATE_LABELS.some((d) => l.startsWith(d)))) return null;

  const activeIdx = lower.findIndex((l, i) => i > 0 && l === "active");
  const active = activeIdx > 0 ? lines[activeIdx - 1] : null;
  const headline = lines.find((l) => HEADLINES.some((h) => l.toLowerCase().startsWith(h)));
  const status = active ?? headline ?? "In transit";
  const delivered = status.toLowerCase().startsWith("delivered") || lower.some((l) => l.startsWith("delivered on"));

  const value = (labels) => {
    for (const label of labels) {
      const j = lower.findIndex((l) => l.startsWith(label));
      if (j < 0) continue;
      const rest = lines[j].slice(label.length).replace(/^[:\s]+/, "").trim();
      if (rest) return rest;
      const next = lines[j + 1];
      if (next) return next;
    }
    return null;
  };
  // a delivery value counts only if it reads as a date: a bare "Delivered" headline is followed by "Latest Update" or the number
  const dated = (labels) => {
    for (const label of labels) {
      for (let j = 0; j < lower.length; j++) {
        if (!lower[j].startsWith(label)) continue;
        const v = lines[j].slice(label.length).replace(/^[:\s]+/, "").trim() || lines[j + 1];
        if (v && day(v)) return v;
      }
    }
    return null;
  };
  const eta = delivered ? dated(["delivered on", "delivery date", "delivered"]) : dated(["estimated delivery", "scheduled delivery", "delivery date"]);
  const steps = lines.slice(0, -1).map((name, i) => ({ name, state: lower[i + 1] }))
    .filter((st) => ["completed", "active", "inactive"].includes(st.state));
  // the phone layout lists them last step first; always read first step first
  if (steps[0]?.state === "inactive" || (steps.at(-1)?.state === "completed" && steps[0]?.state !== "completed")) steps.reverse();
  return { steps, number, status, eta, etaDate: eta ? day(eta) : null, delivered,
    lastLocation: value(["last location"]), service: value(["service"]), shipTo: value(["ship to"]) };
}

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** "Tuesday, October 27 , 9:30 A.M.", "10/27/2026", "Today", "Tomorrow" -> "YYYY-MM-DD". */
export function day(s, now = new Date()) {
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const l = s.toLowerCase();
  if (l.startsWith("today")) return iso(today);
  if (l.startsWith("tomorrow")) return iso(new Date(today.getTime() + 86400000));
  let m = s.match(/(\d{1,2})\/(\d{1,2})\/(\d{4})/);
  if (m) return iso(new Date(+m[3], +m[1] - 1, +m[2]));
  m = s.match(new RegExp(`(${MONTHS.join("|")}) (\\d{1,2})`));
  if (!m) return null;
  let d = new Date(now.getFullYear(), MONTHS.indexOf(m[1]), +m[2]);
  if (d < new Date(now.getTime() - 180 * 86400000)) d = new Date(d.getFullYear() + 1, d.getMonth(), d.getDate());
  return iso(d);
}
