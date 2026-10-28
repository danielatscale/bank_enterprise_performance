-- Rebuilt from Metabase column metadata (database: Bank Enterprise Performance, engine: bigquery-cloud-sdk)
-- Warehouse location: `atscale-sales-demo`.BANK_ENTERPRISE_PERFORMANCE

-- About 1,000 branches. Each branch belongs to one market; geography (state, region) should be taken from the Market table via market_id so all facts roll up the same way. Hierarchy: Region > State > Market > Branch.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_branch` (
  branch_id INTEGER,  -- Branch key.
  branch_name STRING,  -- Branch name. Lowest level of branch geography.
  branch_type STRING,  -- Branch format: Financial Center, In-Store, or Private Bank Office. An attribute of the branch, not a hierarchy level.
  market_id INTEGER,  -- The market this branch belongs to.
  state STRING,  -- Denormalized copy of the market's state. Prefer Market.state.
  region STRING,  -- Denormalized copy of the market's region. Prefer Market.region.
  PRIMARY KEY (branch_id) NOT ENFORCED
  -- FK: market_id -> dim_market(market_id)
);

-- 58,000 customers: 50,000 consumer and 8,000 commercial clients. Hierarchies: Customer Type > Customer Segment > Customer; Industry Vertical (commercial only); Customer Region > Customer State. Customer region is where the customer is located and is separate from branch region.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_customer` (
  customer_id INTEGER,  -- Customer key.
  customer_key STRING,  -- Business customer key, an attribute of the customer.
  customer_name STRING,  -- Customer or client name. Lowest level of the customer hierarchy.
  customer_type STRING,  -- Consumer or Commercial. Top of the customer hierarchy.
  segment STRING,  -- Customer segment. Consumer: Mass Market, Mass Affluent, Private / HNW, Small Business. Commercial: Middle Market, Corporate, Institutional.
  industry_vertical STRING,  -- Industry of commercial clients: Healthcare, Technology, Real Estate, Energy, Industrial, Public Sector, Consumer. 'N/A' for consumer customers.
  revenue_band STRING,  -- Commercial client revenue band, an attribute of the customer. 'N/A' for consumers.
  region STRING,  -- Region where the customer is located.
  state STRING,  -- State where the customer is located. Child of customer region.
  acquisition_date DATE,  -- Date the customer relationship started.
  PRIMARY KEY (customer_id) NOT ENFORCED
);

-- Conformed calendar, one row per day from 2023-07-01 to 2026-06-30. Shared by all four fact tables as the single time axis. Calendar hierarchy: Year > Quarter > Month > Day (fiscal year = calendar year). Deposit and facility snapshots are dated the 1st of each month.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_date` (
  date_id DATE,  -- Calendar day. Lowest level of the calendar hierarchy.
  day_of_week INTEGER,  -- Day of week number (1-7).
  day_name STRING,  -- Day of week name (Monday..Sunday).
  day_of_month INTEGER,  -- Day of month (1-31).
  month_num INTEGER,  -- Month number within the year (1-12).
  month_name STRING,  -- Month name (January..December).
  year_month STRING,  -- Year-qualified month label, format YYYY-MM (e.g. 2025-03). Month level of the calendar hierarchy; unique across years.
  quarter_num INTEGER,  -- Quarter number within the year (1-4).
  quarter_name STRING,  -- Year-qualified quarter label, format 'Qn YYYY' (e.g. 'Q1 2025'). Quarter level of the calendar hierarchy. Sort chronologically by year then quarter number, not alphabetically.
  year_num INTEGER,  -- Calendar year. Top level of the calendar hierarchy. 2023 and 2026 are partial years in this data (Jul-Dec 2023, Jan-Jun 2026).
  is_weekend BOOLEAN,  -- True for Saturday and Sunday.
  is_month_end BOOLEAN,  -- True on the last day of each month. Note: deposit and facility snapshots are dated the 1st of the month, not month-end.
  PRIMARY KEY (date_id) NOT ENFORCED
);

-- The bank's lines of business. Hierarchy: Segment (Consumer Bank / Commercial Bank) > Line of Business (Retail Deposits, Consumer Lending, Commercial Payments, Commercial Real Estate, Middle Market Lending).
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_line_of_business` (
  lob_id INTEGER,  -- Line of business key.
  lob_name STRING,  -- Line of business name.
  segment STRING,  -- Bank segment: Consumer Bank or Commercial Bank. Parent of line of business.
  PRIMARY KEY (lob_id) NOT ENFORCED
);

-- Metro markets in the bank's 15-state footprint. Branch geography hierarchy: Region > State > Market > Branch (Branch comes from the Branch table, which points to its market).
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_market` (
  market_id INTEGER,  -- Market key.
  market_name STRING,  -- Metro market name.
  state STRING,  -- US state of the market.
  region STRING,  -- Geographic region: Great Lakes, Northeast, Pacific, Rocky Mountains. Top of the branch geography hierarchy.
  PRIMARY KEY (market_id) NOT ENFORCED
);

-- 24 banking products across all four lines of business. Hierarchy: Product Line of Business > Product Category > Product.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_product` (
  product_id INTEGER,  -- Product key.
  product_name STRING,  -- Product name (24 products, e.g. HELOC).
  product_category STRING,  -- Product category (18 values), for example Checking, Mortgage, Home Equity, Auto, ACH, RTP, Card, Liquidity, FX, CRE, C&I.
  line_of_business STRING,  -- Line of business the product belongs to. Top of the product hierarchy.
  lob_id INTEGER,  -- Line of business key for the product.
  PRIMARY KEY (product_id) NOT ENFORCED
  -- FK: lob_id -> dim_line_of_business(lob_id)
);

-- Regulatory credit risk ratings for commercial facilities. Hierarchy: Regulatory Class (Pass / Criticized / Classified) > Rating Grade.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.dim_risk_rating` (
  risk_rating_id INTEGER,  -- Risk rating key.
  rating_grade STRING,  -- Regulatory rating grade: 1-3 Strong, 4-6 Acceptable, 7 Special Mention, 8 Substandard, 9 Doubtful.
  regulatory_class STRING,  -- Regulatory classification: Pass, Criticized, or Classified. Parent of rating grade.
  is_nonperforming BOOLEAN,  -- True for grades considered non-performing.
  PRIMARY KEY (risk_rating_id) NOT ENFORCED
);

-- Retail Deposits line of business. One row per branch x deposit product x customer segment x month; each month's snapshot is dated the 1st of that month. Balances and account counts are point-in-time snapshots: for any period, report the value from the latest snapshot in that period and add across branches, products and segments, but never across months. Accounts opened/closed and interest expense are monthly flows and add up over time. customer_segment is stored on this table (no separate segment table).
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.fact_deposit_snapshot` (
  deposit_snapshot_id INTEGER,  -- Row key.
  snapshot_date DATE,  -- Snapshot date: the 1st of the month the snapshot describes. Join to the calendar on this date.
  branch_id INTEGER,  -- Branch holding the deposits. Use this (via Branch > Market) for geography.
  market_id INTEGER,  -- Denormalized copy of the branch's market. Do not join on it; use branch_id for geography.
  product_id INTEGER,  -- Deposit product.
  customer_segment STRING,  -- Retail deposit customer segment: Mass Market, Mass Affluent, Private / HNW, Small Business.
  eom_balance NUMERIC,  -- Deposit balance at the end of the snapshot month. Point-in-time: never add across months.
  avg_daily_balance NUMERIC,  -- Average daily balance for the month. Point-in-time: never add across months.
  account_count INTEGER,  -- Open accounts at the end of the snapshot month. Point-in-time: never add across months.
  accounts_opened INTEGER,  -- Accounts opened during the month (flow).
  accounts_closed INTEGER,  -- Accounts closed during the month, i.e. attrition (flow).
  interest_expense_mtd NUMERIC,  -- Deposit interest expense for the month (flow).
  PRIMARY KEY (deposit_snapshot_id) NOT ENFORCED
  -- FK: snapshot_date -> dim_date(date_id)
  -- FK: branch_id -> dim_branch(branch_id)
  -- FK: product_id -> dim_product(product_id)
);

-- Commercial Real Estate and Middle Market (C&I) lending. One row per credit facility x month; each month's snapshot is dated the 1st of that month. Commitment, outstanding and undrawn amounts are point-in-time snapshots: for any period, report the value from the latest snapshot in that period and add across facilities, but never across months. Interest income is a monthly flow. NIM is a ratio and must be averaged, never added.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.fact_loan_facility_snapshot` (
  facility_snapshot_id INTEGER,  -- Row key.
  snapshot_date DATE,  -- Snapshot date: the 1st of the month the snapshot describes. Join to the calendar on this date.
  facility_id INTEGER,  -- Credit facility identifier. Used only for counting distinct facilities; it has no descriptive attributes.
  customer_id INTEGER,  -- Borrowing client.
  product_id INTEGER,  -- Facility product (e.g. CRE Term, CRE Bridge, C&I).
  lob_id INTEGER,  -- Line of business: Commercial Real Estate or Middle Market Lending.
  risk_rating_id INTEGER,  -- Current regulatory risk rating of the facility.
  commitment_amount NUMERIC,  -- Committed amount as of the snapshot. Point-in-time: never add across months.
  outstanding_balance NUMERIC,  -- Drawn balance as of the snapshot. Point-in-time: never add across months.
  undrawn_amount NUMERIC,  -- Undrawn availability as of the snapshot. Point-in-time: never add across months.
  interest_income_mtd NUMERIC,  -- Interest income for the month (flow).
  nim_bps FLOAT,  -- Net interest margin in basis points. A ratio: average it, never add it.
  is_nonperforming BOOLEAN,  -- True when the facility is non-performing in that month.
  PRIMARY KEY (facility_snapshot_id) NOT ENFORCED
  -- FK: snapshot_date -> dim_date(date_id)
  -- FK: customer_id -> dim_customer(customer_id)
  -- FK: product_id -> dim_product(product_id)
  -- FK: lob_id -> dim_line_of_business(lob_id)
  -- FK: risk_rating_id -> dim_risk_rating(risk_rating_id)
);

-- Consumer Lending line of business. One row per consumer loan booked (mortgage, home equity, indirect auto, specialty). The loan is dated by its origination date. Delinquency status and current balance are as of the latest month (June 2026), not a monthly history.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.fact_loan_origination` (
  loan_id INTEGER,  -- Loan key.
  origination_date DATE,  -- Date the loan was booked. Join to the calendar on this date.
  customer_id INTEGER,  -- Borrower.
  branch_id INTEGER,  -- Originating branch. Use this (via Branch > Market) for geography.
  market_id INTEGER,  -- Denormalized copy of the branch's market. Do not join on it; use branch_id for geography.
  product_id INTEGER,  -- Loan product.
  loan_amount NUMERIC,  -- Originated principal.
  current_balance NUMERIC,  -- Outstanding balance as of the latest month.
  interest_rate_pct FLOAT,  -- Note rate in percentage points (6.40 means 6.4%).
  term_months INTEGER,  -- Loan term in months.
  fico_band STRING,  -- Borrower FICO band at origination.
  ltv FLOAT,  -- Loan-to-value ratio at origination.
  vintage STRING,  -- Origination month (YYYY-MM), used for vintage analysis.
  delinquency_status STRING,  -- Current, 30 DPD, 60 DPD, or 90+ DPD (days past due), as of the latest month.
  days_past_due INTEGER,  -- Days past due as of the latest month.
  PRIMARY KEY (loan_id) NOT ENFORCED
  -- FK: origination_date -> dim_date(date_id)
  -- FK: customer_id -> dim_customer(customer_id)
  -- FK: branch_id -> dim_branch(branch_id)
  -- FK: product_id -> dim_product(product_id)
);

-- Commercial Payments (treasury management) line of business. One row per commercial client x payments product x month. All amounts are monthly flows and add up over time.
CREATE TABLE `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE.fact_payment_transaction` (
  payment_id INTEGER,  -- Row key.
  activity_month DATE,  -- First day of the activity month. Join to the calendar on this date.
  customer_id INTEGER,  -- Commercial client.
  product_id INTEGER,  -- Payments product (ACH, Wire, RTP, Card, Liquidity, FX, ...).
  transaction_count INTEGER,  -- Number of payment transactions in the month.
  payment_volume_usd NUMERIC,  -- Dollar volume processed in the month.
  fee_revenue_usd NUMERIC,  -- Fee revenue earned in the month.
  PRIMARY KEY (payment_id) NOT ENFORCED
  -- FK: activity_month -> dim_date(date_id)
  -- FK: customer_id -> dim_customer(customer_id)
  -- FK: product_id -> dim_product(product_id)
);
