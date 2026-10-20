// Carton web: serves the landing page and web app from web/, and reads UPS tracking pages at /api/track/<number>.
// ups.com blocks plain fetches, so a real headless Chrome (Cloudflare Browser Rendering) loads the page like a person.
import puppeteer from "@cloudflare/puppeteer";
import { parse, isNotFound } from "./parse.js";

const json = (o, status = 200) => new Response(JSON.stringify(o), {
  status, headers: { "content-type": "application/json", "cache-control": status === 200 ? "public, max-age=900" : "no-store" },
});

async function track(env, number) {
  const browser = await puppeteer.launch(env.BROWSER);
  try {
    const page = await browser.newPage();
    await page.setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15");
    await page.setExtraHTTPHeaders({ "accept-language": "en-US,en;q=0.9" });
    await page.goto("https://www.ups.com/us/en/home", { waitUntil: "domcontentloaded", timeout: 20000 }).catch(() => {});  // pick up the site's cookies first
    await page.goto(`https://www.ups.com/track?loc=en_US&tracknum=${number}&requester=ST/trackdetails`, { waitUntil: "domcontentloaded", timeout: 20000 });
    for (let i = 0; i < 40; i++) {  // up to 20s for the page's scripts to render the result
      await new Promise((r) => setTimeout(r, 500));
      await page.evaluate(() => document.querySelectorAll("button").forEach((b) => {
        if (/^\s*shipment details/i.test(b.innerText) && b.getAttribute("aria-expanded") !== "true") b.click();
      }));
      const text = await page.evaluate(() => document.body ? document.body.innerText : "");
      if (isNotFound(text)) return { error: "UPS can't find this number yet." , status: 404 };
      const s = parse(text, number);
      if (s) return s;
      if (i === 39) return { error: "UPS didn't answer.", status: 504, sample: text.slice(0, 300) };
    }
  } finally {
    await browser.close();
  }
}

export default {
  async fetch(req, env, ctx) {
    const url = new URL(req.url);
    const m = url.pathname.match(/^\/api\/track\/(1Z[0-9A-Z]{16})$/i);
    if (!m) return env.ASSETS.fetch(req);
    const cache = caches.default;  // 15 minute cache keeps browser minutes down
    const hit = await cache.match(req);
    if (hit) return hit;
    try {
      const r = await track(env, m[1].toUpperCase());
      if (r.error) return json(r, r.status);
      const res = json(r);
      ctx.waitUntil(cache.put(req, res.clone()));
      return res;
    } catch (e) {
      return json({ error: "UPS didn't answer.", detail: String(e.message ?? e) }, 502);
    }
  },
};
