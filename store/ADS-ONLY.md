# Ads-only edition (branch `ads-only`)

This branch has no in-app purchases and no Pro plan. Monetization is AdMob only:
banner on Home and Library, an interstitial after every second analysis, and
rewarded ads that earn one extra analysis.

Differences from `main`:
- `in_app_purchase` and the billing code are removed, there is no paywall or subscriptions.
- When the 3 free monthly analyses are used, the app offers "Watch an ad for 1 extra analysis".
- Daily cap of 10 assistant questions and comparisons for everyone.

When publishing this edition:
- Edit `listings.md`: delete the "Free and Pro" section, the subscription paragraph for the App Store and the subscriptions table. Say "Free, with ads" instead.
- Skip creating subscriptions in the stores.
- Data safety and privacy labels stay the same (ads still collect the advertising ID).
