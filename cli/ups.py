#!/usr/bin/env python3
"""Track UPS packages. Needs UPS_CLIENT_ID + UPS_CLIENT_SECRET (free app at developer.ups.com)."""
import argparse, base64, json, os, sys, uuid
from datetime import date, timedelta
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

BASE = "https://onlinetools.ups.com"  # ponytail: prod only; swap to wwwcie.ups.com to test


def call(req):
    try:
        return json.load(urlopen(req, timeout=20))
    except HTTPError as e:
        body = json.loads(e.read() or "{}")
        err = (body.get("response", {}).get("errors") or [{}])[0].get("message", e.reason)
        sys.exit(f"UPS error {e.code}: {err}")


def token():
    cid, sec = os.environ.get("UPS_CLIENT_ID"), os.environ.get("UPS_CLIENT_SECRET")
    if not (cid and sec):
        sys.exit("set UPS_CLIENT_ID and UPS_CLIENT_SECRET (developer.ups.com > create app > Tracking)")
    auth = base64.b64encode(f"{cid}:{sec}".encode()).decode()
    req = Request(f"{BASE}/security/v1/oauth/token", urlencode({"grant_type": "client_credentials"}).encode(),
                  {"Authorization": f"Basic {auth}"})
    return call(req)["access_token"]


def track(num, tok, locale):
    req = Request(f"{BASE}/api/track/v1/details/{num}?locale={locale}&returnSignature=false",
                  headers={"Authorization": f"Bearer {tok}", "transId": uuid.uuid4().hex, "transactionSrc": "ups-cli"})
    return call(req)["trackResponse"]["shipment"][0]["package"][0]


def ymd(s):
    return date(int(s[:4]), int(s[4:6]), int(s[6:]))


def show(num, pkg, limit, by):
    eta = next(iter(pkg.get("deliveryDate", [])), None)
    print(f"{num}  {pkg['currentStatus']['description']}")
    if eta:
        d = ymd(eta["date"])
        line = f"  {'delivered' if eta['type'] == 'DEL' else 'expected'} {d:%a %b %d}"
        if by:
            line += f"  -> {'ON TIME' if d <= by else 'LATE'} (by {by:%a %b %d})"
        print(line)
    for a in pkg.get("activity", [])[:limit]:
        ad = a.get("location", {}).get("address", {})
        where = ", ".join(x for x in (ad.get("city"), ad.get("stateProvince")) if x)
        print(f"  {ymd(a['date']):%b %d} {a['time'][:2]}:{a['time'][2:4]}  {a['status']['description']}  {where}")
    return eta


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("numbers", nargs="+", help="tracking numbers or ups.com/track URLs")
    p.add_argument("-n", "--limit", type=int, default=5, help="activity rows to show (default 5)")
    p.add_argument("--by", help="deadline: 'tomorrow', 'today' or YYYY-MM-DD; exit 1 if ETA is later")
    p.add_argument("--json", action="store_true", help="raw package JSON")
    p.add_argument("--locale", default="en_US")
    a = p.parse_args()

    by = {"today": date.today(), "tomorrow": date.today() + timedelta(1)}.get(a.by) or (date.fromisoformat(a.by) if a.by else None)
    tok, late = token(), False
    for n in a.numbers:
        n = n.split("tracknum=")[-1].split("&")[0]  # accept pasted URLs
        pkg = track(n, tok, a.locale)
        if a.json:
            print(json.dumps(pkg, indent=2))
            continue
        eta = show(n, pkg, a.limit, by)
        late |= bool(by and (not eta or ymd(eta["date"]) > by))
    sys.exit(late)


if __name__ == "__main__":
    main()
