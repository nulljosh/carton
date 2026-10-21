# Cartons Money

How Cartons makes money. The fleet-wide ledger is `GTM.md` in the Code root.

## Price

$0.99 upfront on the App Store, iPhone, iPad and Mac in one purchase.

## Rail

App Store paid download. Apple keeps 15%, so each sale pays out $0.84.

## Why

The big trackers want an account, a subscription or your inbox. Cartons asks for a dollar, once. The web app at cartons.jaybulb.com stays free, so the landing page is the trial and the store is the checkout.

## Where we are

- 2026-10-20: 1.0.0 in App Review on iOS and Mac. Price moved from free to $0.99 the same day, before the first sale.

## Plans

**A million dollars.** About 1.2 million sales at $0.84. That is a top-chart utility for a couple of years: every carrier (v25), widgets and Live Activities, and the store page doing the selling. No ads, no account, still one price.

**A billion dollars.** A dollar app can't get there. That needs Cartons to become the place packages are understood: carrier report cards from millions of real deliveries (v45), returns and refunds (v50), and a paid tier for small shops who ship and want their customers to see one calm page. Revenue from shops, not from people tracking a box.

**A trillion dollars.** That is a logistics network, not an app. Owning the last mile, or the data layer every carrier and retailer reads from. Write it down so the joke is on paper, then go back to shipping v1.1.

## Next

Watch App Store Connect sales once 1.0 is live. If a month passes with web visits and no store sales, go back to free and sell something else later.

## Change it

`asc pricing schedule create --app 6825115360 --price-point <id> --base-territory US --start-date YYYY-MM-DD`; the 0.99 point id comes from `asc pricing tiers --app 6825115360 --territory US`. Use `--free` to revert. No build, no review.

*ASC 6825115360. Set 2026-10-20.*
