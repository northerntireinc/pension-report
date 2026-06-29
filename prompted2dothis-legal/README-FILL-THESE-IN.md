# Prompted2DoThis — Stripe-ready policy pages

Three drop-in HTML pages for the website Stripe reviews:

- `terms.html` — Terms of Service
- `privacy.html` — Privacy Policy
- `refund-policy.html` — Refund & Cancellation Policy

They cross-link to each other using `/terms.html`, `/privacy.html`, `/refund-policy.html`.
Add those same links to your site **footer** so a Stripe reviewer (and customers) can find
them from any page. Rename the files if your site uses different routes — just keep the
links consistent.

## 1. Find-and-replace these placeholders (same in all 3 files)

| Placeholder | What to put |
|---|---|
| `[COMPANY LEGAL NAME]` | Your registered business name (must match your Stripe account + the statement descriptor customers see on their card). |
| `[WEBSITE — e.g. prompted2dothis.com]` | Your domain. |
| `[CONTACT EMAIL]` | A support email you actually monitor. |
| `[MAILING ADDRESS]` | Business mailing address. |
| `[EFFECTIVE DATE]` | The date you publish (e.g. June 29, 2026). |
| `[STATE]`, `[COUNTY / CITY, STATE]` | Governing-law state/venue (in `terms.html`). |
| `[3 / 6 / 12]` | Liability-cap window in `terms.html` §9 — pick one. |

## 2. Decisions to make

- **Refund stance** — `refund-policy.html` §3 has three options (A money-back, B
  case-by-case, C all sales final). **Pick one, delete the other two**, and delete the
  orange "choose one" box. Make sure it matches how you actually handle refunds in Stripe.
  Option A (a 7–14 day money-back window) tends to cut down card disputes for digital products.
- **Free trial** — keep `refund-policy.html` §4 only if you offer a trial; otherwise delete it.
- **Analytics/cookies** — in `privacy.html` §4, name any tools you actually use (Google
  Analytics, Meta Pixel, etc.) or remove the bracketed note.
- **Children** — `privacy.html` §8: if your learning app is meant for minors/students, that
  section needs more (COPPA / student-data rules). If it's adults-only, it's fine as written.
- Delete the blue "Not legal advice" boxes before going live.

## 3. Stripe website checklist — how these map

| Stripe wants to see | Where it's covered |
|---|---|
| Clear description of what you sell | Your homepage + Terms §1 |
| Pricing & billing terms (subscription, auto-renew) | Your checkout/pricing page + Terms §3, Refund §1 |
| Business / legal name visible | Footer + all 3 pages |
| Contact information | All 3 pages + add to footer |
| Terms of Service | `terms.html` |
| Privacy Policy | `privacy.html` |
| Refund / Cancellation policy | `refund-policy.html` |
| Secure checkout (HTTPS) | Already in place |

Two items live on your *site itself*, not in these files — make sure they're visible:
1. **Pricing** with billing interval (monthly/annual) shown before purchase.
2. **Footer links** to all three pages from every page.

> Not legal advice — have a licensed attorney review these for your business and jurisdiction.
