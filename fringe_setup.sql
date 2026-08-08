-- ============================================================
-- NTI FRINGE BENEFIT REPORT (Form 3029) — one-time setup
-- Run this in the SQL editor of the PAYROLL Supabase project
-- (ogmvswqcvzohizjfgixm). Safe to re-run: uses IF NOT EXISTS
-- and ON CONFLICT.
-- ============================================================

create table if not exists fringe_employees (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,           -- exactly as it prints on the form
  ssn text not null,
  birthdate date not null,
  active boolean not null default true,
  sort_order int not null default 0,
  unique (full_name)
);

create table if not exists fringe_rates (
  contract_year text not null,       -- e.g. '2026-27' (June 1 – May 31)
  benefit text not null check (benefit in ('TRAINING','HEALTH','PENSION')),
  rate numeric(8,4) not null,
  primary key (contract_year, benefit)
);

create table if not exists fringe_hours (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references fringe_employees(id) on delete cascade,
  work_month date not null,          -- always the 1st of the month
  hours numeric(8,2) not null default 0,
  source text not null default 'manual',   -- 'manual' or 'timeclock'
  updated_at timestamptz not null default now(),
  unique (employee_id, work_month)
);

-- Lock everything behind login (SSNs live here — never expose to anon)
alter table fringe_employees enable row level security;
alter table fringe_rates enable row level security;
alter table fringe_hours enable row level security;

drop policy if exists "auth all fringe_employees" on fringe_employees;
create policy "auth all fringe_employees" on fringe_employees
  for all to authenticated using (true) with check (true);

drop policy if exists "auth all fringe_rates" on fringe_rates;
create policy "auth all fringe_rates" on fringe_rates
  for all to authenticated using (true) with check (true);

drop policy if exists "auth all fringe_hours" on fringe_hours;
create policy "auth all fringe_hours" on fringe_hours
  for all to authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- Seed: 2026-27 contract year rates (from your workbook)
-- ------------------------------------------------------------
insert into fringe_rates (contract_year, benefit, rate) values
  ('2026-27','TRAINING', 0.30),
  ('2026-27','HEALTH',   9.74),
  ('2026-27','PENSION',  6.81)
on conflict (contract_year, benefit) do update set rate = excluded.rate;

-- ------------------------------------------------------------
-- Seed: employees (fill in SSN/birthdate from your records —
-- left as placeholders here so this script is safe to share)
-- ------------------------------------------------------------
insert into fringe_employees (full_name, ssn, birthdate, sort_order) values
  ('FORBES, JEREMY M.',  'XXX-XX-XXXX', '1900-01-01', 1),
  ('KERTSCHER, JEFFERY', 'XXX-XX-XXXX', '1900-01-01', 2),
  ('JOHNSON, BODE',      'XXX-XX-XXXX', '1900-01-01', 3)
on conflict (full_name) do nothing;

-- After running, update each row with the real SSN and birthdate
-- from your workbook, e.g.:
--   update fringe_employees set ssn = '___-__-____', birthdate = 'YYYY-MM-DD'
--   where full_name = 'FORBES, JEREMY M.';

-- ------------------------------------------------------------
-- Seed: June + July 2026 hours (from your workbook)
-- ------------------------------------------------------------
insert into fringe_hours (employee_id, work_month, hours, source)
select id, d.m::date, d.h, 'manual'
from fringe_employees e
join (values
  ('FORBES, JEREMY M.',  '2026-06-01', 173.50),
  ('FORBES, JEREMY M.',  '2026-07-01', 218.00),
  ('KERTSCHER, JEFFERY', '2026-06-01', 163.75),
  ('KERTSCHER, JEFFERY', '2026-07-01', 206.50),
  ('JOHNSON, BODE',      '2026-06-01', 168.75),
  ('JOHNSON, BODE',      '2026-07-01', 210.75)
) as d(name, m, h) on d.name = e.full_name
on conflict (employee_id, work_month) do update set hours = excluded.hours;

-- ============================================================
-- OPTIONAL: auto-pull hours from the time clock
-- Replace time_entries / clock_in / clock_out / employee match
-- with your actual kiosk table + columns, then the report page's
-- "Sync from time clock" button fills the month automatically.
-- ============================================================
create or replace function sync_fringe_hours(p_month date)
returns void
language plpgsql
security invoker
as $$
begin
  -- EDIT THIS QUERY to match your time clock schema:
  --
  -- insert into fringe_hours (employee_id, work_month, hours, source)
  -- select fe.id,
  --        date_trunc('month', p_month)::date,
  --        round(sum(extract(epoch from (t.clock_out - t.clock_in)) / 3600.0)::numeric, 2),
  --        'timeclock'
  -- from time_entries t
  -- join fringe_employees fe on fe.full_name = t.employee_name
  -- where date_trunc('month', t.clock_in)::date = date_trunc('month', p_month)::date
  -- group by fe.id
  -- on conflict (employee_id, work_month)
  --   do update set hours = excluded.hours, source = 'timeclock', updated_at = now();

  raise notice 'Edit sync_fringe_hours() to point at your time clock table.';
end;
$$;
