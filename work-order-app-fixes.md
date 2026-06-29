# AI Work Orders — fixes to apply in the work-order repo

Carry this into the new session scoped to the work-order GitHub repo. The design port
already matches the spec; these are correctness/security fixes found reviewing the app's
`index.html`. Apply 1–3 as written; #4 (pricing) needs the real offer first.

---

## 1. Duplicate work-order number bug  ✅ ready

**Problem:** `CreateWO.save()` reads `tenant.next_wo_number` from the in-memory prop, uses it
as the WO `id` (primary key), then bumps the counter in the DB only. The local `tenant` never
updates, so the **2nd** WO created in a session reuses the same id → PK collision → insert
fails. Also racy across users.

**Fix — make it atomic with a DB function.**

Migration (run in the work-order Supabase project):
```sql
create or replace function next_wo_number(p_tenant uuid)
returns integer language plpgsql security definer as $$
declare n integer;
begin
  update tenants set next_wo_number = next_wo_number + 1
   where id = p_tenant
   returning next_wo_number - 1 into n;
  return n;
end $$;
```

In `CreateWO.save()`, replace the id/bump logic:
```js
// OLD:
//   const next = (tenant.next_wo_number || 1000);
//   const woId = String(next);
//   ...insert...
//   await supabase.from("tenants").update({ next_wo_number: next + 1 }).eq("id", tenant.id);

// NEW:
const { data: n, error: numErr } = await supabase.rpc("next_wo_number", { p_tenant: tenant.id });
if (numErr) throw numErr;
const woId = String(n);
// ...insert work_orders with id: woId...
// (delete the separate next_wo_number update — the RPC already bumped it)
```

---

## 2. Invoice push trusts the client  ✅ ready (client) + edge-function change

**Problem:** `pushToQbo()` calls the edge function with the **publishable key** as the bearer
token and posts the whole `wo` object + `tenant_id` from the browser. No user identity is sent,
the function can't verify tenant ownership, and client-sent line items/amounts are trusted for a
real invoice. This is the kind of thing Stripe/Intuit security review flags hardest in a
multi-tenant app.

**Client fix — send the user's session token and only the `wo_id`:**
```js
const { data: { session } } = await supabase.auth.getSession();
const res = await fetch(`${SUPABASE_URL}/functions/v1/qbo-create-invoice`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "apikey": SUPABASE_KEY,
    "Authorization": `Bearer ${session.access_token}`,  // the USER, not the publishable key
  },
  body: JSON.stringify({ wo_id: wo.id }),                // function loads the WO itself
});
```

**Edge-function side (`qbo-create-invoice`) must:**
- Verify the JWT and get the user id.
- Look up the user's tenant via `tenant_users` and confirm membership + `can_invoice`.
- **Re-read the work order from the DB by `wo_id` scoped to that tenant** — do not trust amounts
  posted from the browser.
- Build the QBO invoice from the DB row, then return `{ success, invoiceNum, invoiceId }`.

---

## 3. Blank lines get saved  ✅ ready

**Problem:** new lines default to `qty: 1`, and the valid-line filter treats `Number(l.qty)` as
truthy — so an untouched starter line (qty 1, rate 0, no item/desc) saves as a $0 line.

**Fix — require an item/description or a non-zero rate:**
```js
const validLines = lines.filter(l =>
  l.item.trim() || l.desc.trim() || Number(l.rate) > 0
);
```

---

## 4. Pricing — RECONCILE (needs the real offer)  ⛔ blocked on decision

The app and the website currently disagree, and neither shows the $7.99 you mentioned:

| Surface | Currently says |
|---------|----------------|
| App landing / signup | "Start Free 14-Day Trial", "No credit card required" |
| App `PLANS` array | Basic $10 · +GPS $19 · Service Pro $29 |
| Marketing website | **$7.99/mo introductory offer** |

Decide the real structure, then make both match. If **$7.99/mo introductory** is the truth, the
app needs:
- Landing button copy (`Landing`): drop "Free 14-Day Trial".
- Signup copy (`SignUp`): drop "free 14-day trial / no credit card".
- `PLANS` array prices, and the wizard step-2/step-3 copy.
- Signup should collect a card via **Stripe Checkout** rather than start a no-card trial
  (the `tenants` table already has `stripe_customer_id` / `stripe_sub_id` / `subscription_status`).

If instead it's genuinely a free trial then $10/$19/$29, fix the **website** instead
(`p2dt-website.html` in the pension repo — currently shows $7.99 introductory).

---

## 5. Smaller items

- **No "Connect QuickBooks" flow yet** — chip shows "Disconnected" and the push card says
  "we'll add this to Settings shortly." You can't invoice until QBO OAuth connect exists; this is
  the next real build item (and a hard requirement for the QuickBooks App Store listing).
- **`user-scalable=no`** in the viewport meta disables pinch-zoom (accessibility) — consider
  dropping `maximum-scale=1.0, user-scalable=no`.
- Line `qty`/`rate` are stored as strings from the inputs; make sure the edge function coerces
  with `Number()` when building the QBO invoice.
