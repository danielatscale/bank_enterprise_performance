# Bank Enterprise Performance — AtScale SML Model

Unified enterprise-performance semantic model for a US retail + commercial bank, generated
by the `atscale-sml-model-generator` skill. A constellation (galaxy) schema: four lines of
business share seven conformed dimensions so any single area can be analyzed and the whole
bank rolled up along the same axes (time, geography, product, line of business, customer).

## Inputs

Every input the skill consumed is copied verbatim into `context/` (including the original
archive, `bank_enterprise_performance_context.zip`).

- **`use_case.md`** — Bank Enterprise Performance use case: four LOBs (Retail Deposits,
  Consumer Lending, Commercial Payments, CRE + Middle Market), personas, NLQs, engineered
  stories, grain/semantics table, and known limitations.
- **`02_ddl.sql`** — BigQuery Standard SQL DDL: 7 conformed dimensions + 4 fact tables.
- **`data_profile.yaml`** — Auto-profiled column types, null counts, distinct counts, and
  value lists (seed 42) for all 11 tables. Used to derive `is_unique_key` (Rule 16).
- **`erd.mmd`** — Mermaid ERD confirming the intended joins (PK/FK are NOT ENFORCED in
  BigQuery; joins live in this semantic model).
- **NLQs** — Embedded in `use_case.md` under "What the data is shaped to answer" (brief
  NLQs + engineered stories). No separate NLQ file was provided to the skill.
- **Target warehouse** — Google BigQuery (`atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE`).
- **`build.yaml`** — (not provided) All build parameters derived from inputs + defaults.

## Build parameters

- **unrelated_dimension_handling** = `repeat` — applied to every base metric (Rule 3).
- **warehouse** = `BigQuery` — from `use_case.md` target platform and lowercase DDL identifiers.
- **model_unique_name** = `bank_enterprise_performance`
- **catalog_unique_name** = `bank_enterprise_performance_catalog` (Rule 8c).
- **currency** = `USD` — stated in the use case (single currency, no FX).
- **time_window** = `calendar` — Gregorian calendar (2023-07-01 .. 2026-06-30); no fiscal/retail markers.
- **use_cases_covered** = all four LOB sections + cross-LOB.
- **use_cases_excluded** = none.
- **semi_additive_default** = `last_non_empty` — for the two snapshot facts
  (`fact_deposit_snapshot`, `fact_loan_facility_snapshot`); the two transactional facts
  (`fact_loan_origination`, `fact_payment_transaction`) are additive.

## Assumptions and decisions

- **warehouse = BigQuery** — from use case target platform; all DB-side identifiers emitted lowercase (Rule 1).
- **database = atscale-sales-demo / schema = BANK_ENTERPRISE_PERFORMANCE** — the DDL parameterizes these as `${PROJECT}.${DATASET}` (loader variables, not valid SML); resolved to the concrete values named in the use case target platform (Rule 17). Override in `connections/` per workspace if the data lands elsewhere.
- **Date is a single conformed dimension, NOT role-played** — the use case frames one unified time axis shared by all four facts. Each fact joins `Date Dimension` once on its own date column (`snapshot_date` / `origination_date` / `activity_month`); no `role_play` prefixes are used. Time-intelligence calcs therefore reference `[Date Dimension].[Date Hierarchy]` directly and shift each fact along its own date relationship (Rule 2/4 are satisfied trivially — there is one date axis).
- **Branch geography modeled as one snowflaked dimension** (Region > State > Market > Branch) — Market/Region/State sourced from `dim_market`, Branch from `dim_branch`, joined intra-dimension on `market_id` (Rule 5). Market is a visible bridge, so Branch follows it in the same hierarchy (Rule 11). Facts join at the Branch level via `branch_id`; the redundant `market_id` FK on the deposit/origination facts is not separately joined (branch rolls up to market).
- **Deposit Segment is a degenerate dimension** on `fact_deposit_snapshot` (`customer_segment` is fact-resident) — `is_degenerate: true`, no `type:`, listed in the model `dimensions:` block, no `is_unique_key` (Rule 12, 16).
- **Snapshot balances are semi-additive last-non-empty over the snapshot date** — `EOM Balance`, `Average Daily Balance`, `Deposit Account Count` (deposits) and `Commitment Amount`, `Outstanding Balance`, `Undrawn Amount`, `Nonperforming Balance` (facilities). All use `calculation_method: sum` (additive across entities, non-additive over time) — never `average` (Rule 19).
- **Net Interest Margin (bps) uses `average`, NOT semi-additive** — `nim_bps` is a ratio; averaging is correct and it carries no `semi_additive:` block, so Rule 19 does not apply.
- **`is_unique_key` derived from the data profile** (Rule 16): set `true` only where `distinct == row_count` — Day (`date_id` 1096=1096), Line of Business (`lob_id` 5=5), Market (`market_id` 30=30), Branch (`branch_id` 1000=1000), Product (`product_id` 24=24), Rating Grade (`risk_rating_id` 5=5), Customer (`customer_id` 58000=58000). Region/State/Segment/Category levels are non-unique within their dim tables → flag omitted.
- **Calculated columns added** (semantic-layer, no ETL): `prior_year_num` and `quarter_sort` on `dim_date` (year-over-year ParallelPeriod + chronological quarter ordering, Rule 13); `is_delinquent` / `is_30_dpd` / `is_60_dpd` / `is_90_dpd` on `fact_loan_origination` (delinquency-rate metrics); `nonperforming_outstanding` on `fact_loan_facility_snapshot` (NPL-balance story).
- **`facility_id` NOT modeled as a dimension** — it is a degenerate facility key with no descriptive attributes; facility population is exposed as the `Facility Count` metric (`count distinct facility_id`) instead of a browsable dimension.
- **`market_id` direct FK on facts not separately joined** — reachable via the Branch snowflake; a second Market join would be redundant.
- **No customer/company name in logical metadata** (Rule 18) — the dataset is brand-neutral by design; model/catalog/dimension/metric names are all domain-generic. The physical schema name `BANK_ENTERPRISE_PERFORMANCE` is a warehouse identifier (Rule 17), not a customer name.
- **unrelated_dimension_handling = repeat** — skill default; no `build.yaml` override supplied.

## Generation summary

- **Datasets:** 11 (7 dimension sources + 4 facts).
- **Dimensions:** 7 — Date (time), Line of Business, Branch (snowflake), Product, Risk Rating,
  Customer (3 hierarchies), Deposit Segment (degenerate).
- **Base metrics:** 26 — 6 deposits, 9 consumer lending, 4 commercial payments, 7 CRE/MM.
- **Calculations:** 13 — 4 ratios (Avg Loan Size, Any-DPD Rate, 90+ DPD Rate, NPL Ratio) +
  9 time-intelligence (prior-year / YoY-growth / YTD via `ParallelPeriod` and `PeriodsToDate`).
- **Relationships:** 15 fact-to-dimension joins across the 4 facts.
- **Role-play prefixes:** none — Date is a single conformed axis by design.
- **Snowflake bridges:** 1 — Branch Dimension (`dim_branch.market_id` → Market level).
- **Calculated columns:** 7 (2 on dim_date, 4 on fact_loan_origination, 1 on fact_loan_facility_snapshot).
- **Caveats:** Deposits and CRE/MM are monthly snapshots (semi-additive); consumer-loan
  delinquency is a single as-of-current state, not a monthly roll-forward; commercial payments
  are monthly client×product aggregates. Line of Business as a dedicated dimension joins only
  the facility fact (the sole fact with `lob_id`); other facts roll up by LOB via the Product
  dimension's Line of Business level.

## Reproducing this build

`context/` holds verbatim copies of every input the skill consumed — the original archive
`bank_enterprise_performance_context.zip` plus its extracted `use_case.md`, `02_ddl.sql`,
`data_profile.yaml`, and `erd.mmd`. Re-running the skill with these same inputs and the build
parameters above should produce an equivalent model.
