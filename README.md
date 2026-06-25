# Northern Tire — Local 324 Fringe Remittance

Single-file web app for Northern Tire, Inc. that produces the Operating Engineers
Local 324 Shop Agreement fringe-benefit remittance (Form 3022 + Form 326) and a
weekly payroll-hours email to Tandem Tax.

Everything lives in **`index.html`** — no build step, no dependencies, no server.
Open it in any browser or serve it from GitHub Pages.

## What it does

- **Shop Report** — enter or import worked hours plus sick/vacation days per employee.
- **Print / File** — two facsimile filings each month (union Shop + salary/management),
  each with its 3022 remittance and 326 detail page. Includes a one-tap payroll email
  to Tandem Tax, a reminder email, and a holiday "send early" heads-up when a pay-Friday
  is a federal holiday.
- **Summary** — roll up hours and fund dollars across a month, quarter, year, or custom
  month range (records / reconciliation view).
- **Filings** — a saved, snapshotted history of each remittance filed.
- **Forms** — store the union's current blank forms (photo/screenshot) on the device.
- **Contract** — when a new agreement takes effect, enter the changed premiums (fund
  rates), minimum hours, and hours cap; the app applies them everywhere and logs the
  change with its effective date (with revert).
- **Employees** / **Setup & Rates** — people, funds, rates, pay-period rule, email targets.

## Pay period

Periods hard-lock to the **last Friday** of each month: weeks run Sun–Sat and are paid
the following Friday, so a month's period ends the Saturday before its last Friday and
the week count equals the number of Fridays in the month. Override per month if needed.

## Data & privacy

All data is stored in the browser's **localStorage** on the device that enters it.
It is **per-device / per-browser** — it does not sync between phones or computers, and
nothing is sent anywhere. Clearing the browser's site data erases it. For a shared,
synced dataset across users, this would need a backend (e.g. Supabase).

## Deploy (GitHub Pages)

1. Put `index.html`, `README.md`, and `.nojekyll` in the repo root.
2. **Settings → Pages → Source: `main` / `/ (root)` → Save.**
3. The site URL appears on that page once it builds.

`.nojekyll` tells Pages to serve the files as-is (no Jekyll processing).

## Notes

- The printed forms are faithful black-and-white **facsimiles** of the union forms; the
  form number and revision are editable under Setup.
- There is **no hours minimum** by default (fringes figured on actual hours). A floor or
  cap can be set on the Contract tab if a future agreement requires one.

_Private repository. Northern Tire, Inc._
