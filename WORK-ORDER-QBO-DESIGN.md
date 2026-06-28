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

- The header **tenant name/logo** is the only per-tenant chrome — swap it on sign-in; the step
  flow and entry grid are identical for every tenant.
- Scope every `work_orders` read/write by tenant (RLS / `tenant_id`); the QBO connection
  (`qbo_tokens`: access/refresh/realm) is **per tenant** too, so the "Connected" chip reflects
  the signed-in tenant's QuickBooks link.
- The green→orange→blue/red step model and counts are per-tenant views of that tenant's data.

## 7. Port checklist

- [ ] Drop in the shell tokens + step ribbon (3 colored cards, active = inset ring).
- [ ] Rebuild the create form as a QBO line-item grid (borderless cells, live Amount, green save).
- [ ] Open list = orange-railed cards with an `open` pill and a blue-outline "Create invoice → QBO" button.
- [ ] Invoice step = read-only summary + blue-outlined QBO push (red accent) → write-back.
- [ ] Bind the tenant name in the header; keep everything else tenant-agnostic.
