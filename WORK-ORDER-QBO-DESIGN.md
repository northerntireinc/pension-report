# Work Order app — QuickBooks design spec

A portable style + flow guide to make the **multi-tenant work order app** look like the
pension app and feel like entering QuickBooks. Paste this into the work-order ("p2dt")
chat to apply it there — the live app's code isn't in this repo.

A clickable reference is in **`work-order-prototype.html`** (open it in any browser). It runs
on local demo data — no live Supabase/QBO — and uses the real `work_orders` field names so
the look ports 1:1.

---

## 1. The sequenced step flow (start → finish)

Lay the app out as three steps, left → right, the way the pension app sequences its work.
Each step is a colored card; the active step gets a 2px inset ring in its own color.

| # | Step | Color | Meaning |
|---|------|-------|---------|
| 1 | **Create Work Order** | **GREEN** `#1f8a3b` | Start. New WO: customer, technician, line items. Saves as `status:'open'`. |
| 2 | **Open Work Orders** | **ORANGE** `#c4791a` | In progress. The list of open WOs awaiting an invoice. |
| 3 | **Create Invoice → QBO** | **BLUE outline `#2c5b8a` + RED accent `#a8341f`** | Finish. Push to QuickBooks, stamp `invoice_no`, mark `status:'invoiced'`. |

The orange step shows a live count of open work orders (the queue). Step 3's button is a
white button with a blue outline and a small red dot — outline, not filled, because it's the
commit action that leaves your app and writes to QuickBooks.

## 2. Color tokens (CSS variables)

```css
/* shared pension-app shell */
--ink:#15212e; --paper:#f6f4ee; --card:#fff; --line:#d8d2c4; --muted:#6b7480; --brass:#b07a26;
/* traffic-light step colors */
--go:#1f8a3b;  --go-soft:#e4f4e8;  --go-line:#a8d8b6;   /* 1 create  */
--wip:#c4791a; --wip-soft:#fbeed8; --wip-line:#e7c389;  /* 2 open    */
--inv:#2c5b8a; --inv-soft:#e6eef6; --inv-line:#a9c4de;  /* 3 invoice */
--red:#a8341f;                                          /* invoice accent */
/* QuickBooks Online green */
--qb:#2ca01c; --qb-dark:#108000;
```

## 3. Make entry feel like QuickBooks

- **Customer at the top**, then date and technician — like opening a QBO invoice.
- **Line-item grid** with QBO columns: `#  ·  Product/Service  ·  Description  ·  Qty  ·  Rate  ·  Amount  ·  ⌫`.
  - Cell inputs are borderless until hover/focus (QBO's quiet grid), then the cell outlines green.
  - `Amount = Qty × Rate`, right-aligned, tabular numerals, recomputed live.
  - Below the grid: **＋ Add lines** and **✕ Clear all lines** as green text links.
- **Totals box** bottom-right: Subtotal, then a bold **Total** with a heavy top rule (QBO balance box).
- **Save** is the QuickBooks green (`--qb`); inputs focus-ring in the same green.
- Header carries a **"QuickBooks Connected"** chip with a green dot (gray when disconnected).

## 4. Data model — already matches

The `work_orders` table maps straight onto the UI (no new columns needed):

```
id · date · customer · lines(jsonb) · status('open'|'invoiced')
invoice_no · notes · created_at · email_sent · technician · invoiced_by
```

`lines` is the line-item grid: `[{ item, desc, qty, rate }]` (amount is derived).

## 5. Where the real calls go (`// WIRE:` in the prototype)

- **Save WO** → Supabase insert into `work_orders` (status defaults to `'open'`).
- **Create invoice** → QBO create-invoice, then Supabase update:
  `status='invoiced'`, `invoice_no=<from QBO>`, `invoiced_by=<current user>`, `email_sent` per send.

## 6. Multi-tenant notes

- The app is **not tied to any one company or person.** No tenant name, customer, or technician
  is hardcoded or used as a default — `technician` is an optional free-text field, and all
  suggestions come from that tenant's own data. (Drop the `'Jeremy Forbes'` default on
  `work_orders.technician` in the live schema; let it default to empty.)
- The header **tenant name/logo** is the only per-tenant chrome — swap it on sign-in; the step
  flow and entry grid are identical for every tenant.
- Scope every `work_orders` read/write by tenant (RLS / `tenant_id`); the QBO connection
  (`qbo_tokens`: access/refresh/realm) is **per tenant** too, so the "Connected" chip reflects
  the signed-in tenant's QuickBooks link.
- The green→orange→blue/red step model and counts are per-tenant views of that tenant's data.

## 6a. Schema migration — drop the person default

> **Not needed for the live p2dt app.** Verified against the real `ai-work-orders` project:
> `work_orders.technician` **already defaults to `''`**, and technicians are managed in a
> per-tenant `technicians` table (with an `is_default` flag). The hardcoded `'Jeremy Forbes'`
> default only existed in the older standalone `nti work orders` project. The SQL below is kept
> **only** as reference for that old project — do **not** run it against p2dt.

If you ever do need it on a project that still carries the person default, run this in that
Supabase project (with its org connected):

```sql
-- new work orders no longer default to a person
ALTER TABLE public.work_orders ALTER COLUMN technician DROP DEFAULT;
ALTER TABLE public.work_orders ALTER COLUMN technician SET DEFAULT '';
```

Optional cleanup — only if existing rows were auto-stamped with the old default and were never
actually assigned that tech. **Review first**; this is not reversible:

```sql
-- inspect before running the update
SELECT id, customer, technician FROM public.work_orders WHERE technician = 'Jeremy Forbes';

-- then, if those were just the default (not real assignments):
UPDATE public.work_orders SET technician = '' WHERE technician = 'Jeremy Forbes';
```

## 7. Port checklist

- [ ] Drop in the shell tokens + step ribbon (3 colored cards, active = inset ring).
- [ ] Rebuild the create form as a QBO line-item grid (borderless cells, live Amount, green save).
- [ ] Open list = orange-railed cards with an `open` pill and a blue-outline "Create invoice → QBO" button.
- [ ] Invoice step = read-only summary + blue-outlined QBO push (red accent) → write-back.
- [ ] Bind the tenant name in the header; keep everything else tenant-agnostic.

---

## 8. Go-live — listing on the QuickBooks App Store

To **sell** this app you list it on the QuickBooks App Store, which means passing Intuit's
**three-part review: Technical → Security → Marketing.** You can't list until all three pass,
and listed apps are **re-reviewed annually**. Build the items in §8.3 in *before* you call the
app "done" — retrofitting them after a failed review is the slow path.

### 8.1 The gate sequence

1. **Production keys.** In the Intuit Developer portal, complete the **App Assessment
   Questionnaire** + app details under **Production Settings**. That unlocks production OAuth
   keys (the app currently runs on development keys).
2. **Technical review (~20 days).** Validated against Intuit's **14 technical requirements**.
3. **Security review (the long pole).** A real **security assessment — penetration test,
   encryption checks, vulnerability scans.** You must remediate every **critical / high /
   medium** finding in Intuit's written report before listing. Budget *weeks*, possibly a paid
   third-party pentest. Multi-tenant apps are scrutinized hardest here.
4. **Marketing review.** Listing assets: logo, screenshots, description, **support URL,
   privacy policy, terms of service / EULA.**

### 8.2 Timeline

Technical review alone averages **~20 days**; security review + remediation adds weeks. Plan on
roughly **1.5–3 months** from "feature complete" to "listed," dominated by security.

### 8.3 Pre-submission checklist (build these in now)

- [ ] **OAuth 2.0** with correct **token refresh** and **revocation** (we have `qbo_tokens`:
      access / refresh / realm — verify refresh + revoke paths).
- [ ] **Official "Connect to QuickBooks" button** using Intuit's branding assets — replace the
      placeholder connection chip in the prototype.
- [ ] **Disconnect flow + disconnect webhook** — handle the user disconnecting from either side;
      stop calling their data on disconnect.
- [ ] **Tenant isolation a pentest can't break** — RLS scoping every `work_orders` read/write by
      tenant. *(Most likely thing to fail security review.)*
- [ ] **Encrypt the QBO tokens at rest** — `qbo_tokens` per tenant, not plaintext columns.
- [ ] **API error handling + throttle/retry** behavior.
- [ ] **Production end-to-end test** against a real QBO company.
- [ ] **Privacy policy + Terms of Service / EULA** pages (cheap to do early; required to list).

### 8.4 Money note

Most QuickBooks App Store apps **bill their own customers** (your own subscription / Stripe) —
Intuit lists you, it does not run your billing. Confirm this on the developer portal **before**
building a pricing flow, so you don't assume Intuit handles charging.

**Sources:** Intuit Developer — [technical requirements](https://developer.intuit.com/app/developer/qbo/docs/go-live/publish-app/technical-requirements),
[security requirements](https://developer.intuit.com/app/developer/qbo/docs/go-live/publish-app/security-requirements),
[publishing requirements](https://developer.intuit.com/app/developer/qbo/docs/go-live/publish-app/platform-requirements),
[what to expect during review](https://developer.intuit.com/app/developer/qbo/docs/go-live/list-on-the-app-store/what-to-expect-during-the-review).
