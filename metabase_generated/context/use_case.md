# Bank Enterprise Performance: business catalog (exported from Metabase)

**Source:** Metabase MCP server, database `Bank Enterprise Performance` (bigquery-cloud-sdk)  
**Warehouse:** `atscale-sales-demo.BANK_ENTERPRISE_PERFORMANCE`

US regional + commercial bank, enterprise performance. Four lines of business (Retail Deposits, Consumer Lending, Commercial Payments, CRE + Middle Market) share seven conformed dimension tables, so every area can be analyzed alone or rolled up across the whole bank by date, region, product, line of business and customer. Currency is USD. Data covers 2023-07-01 to 2026-06-30. Deposit and facility balances are monthly snapshots dated the 1st of each month (2023-07-01 to 2026-06-01).

## Collection: Bank Enterprise Performance - Business Catalog

Governed business definitions for bank KPIs. Each metric states its calculation in SQL-like terms and its business rules in plain English. Rules such as 'never add balances across months' are part of the definition and must be honored by any tool that reports the metric.

## Tables

### Retail Deposits (monthly snapshot) (`fact_deposit_snapshot`, 409,788 rows)

Retail Deposits line of business. One row per branch x deposit product x customer segment x month; each month's snapshot is dated the 1st of that month. Balances and account counts are point-in-time snapshots: for any period, report the value from the latest snapshot in that period and add across branches, products and segments, but never across months. Accounts opened/closed and interest expense are monthly flows and add up over time. customer_segment is stored on this table (no separate segment table).

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| deposit_snapshot_id | Deposit Snapshot ID | INTEGER | type/PK | Row key. |
| snapshot_date | Snapshot Date | DATE | FK → dim_date.date_id | Snapshot date: the 1st of the month the snapshot describes. Join to the calendar on this date. |
| branch_id | Branch ID | INTEGER | FK → dim_branch.branch_id | Branch holding the deposits. Use this (via Branch > Market) for geography. |
| market_id | Market ID | INTEGER |  | Denormalized copy of the branch's market. Do not join on it; use branch_id for geography. |
| product_id | Product ID | INTEGER | FK → dim_product.product_id | Deposit product. |
| customer_segment | Deposit Customer Segment | STRING | type/Category | Retail deposit customer segment: Mass Market, Mass Affluent, Private / HNW, Small Business. |
| eom_balance | End of Month Balance | NUMERIC | type/Currency | Deposit balance at the end of the snapshot month. Point-in-time: never add across months. |
| avg_daily_balance | Average Daily Balance | NUMERIC | type/Currency | Average daily balance for the month. Point-in-time: never add across months. |
| account_count | Open Accounts | INTEGER | type/Quantity | Open accounts at the end of the snapshot month. Point-in-time: never add across months. |
| accounts_opened | Accounts Opened | INTEGER | type/Quantity | Accounts opened during the month (flow). |
| accounts_closed | Accounts Closed | INTEGER | type/Quantity | Accounts closed during the month, i.e. attrition (flow). |
| interest_expense_mtd | Interest Expense | NUMERIC | type/Currency | Deposit interest expense for the month (flow). |

### CRE + Middle Market Facilities (monthly snapshot) (`fact_loan_facility_snapshot`, 244,072 rows)

Commercial Real Estate and Middle Market (C&I) lending. One row per credit facility x month; each month's snapshot is dated the 1st of that month. Commitment, outstanding and undrawn amounts are point-in-time snapshots: for any period, report the value from the latest snapshot in that period and add across facilities, but never across months. Interest income is a monthly flow. NIM is a ratio and must be averaged, never added.

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| facility_snapshot_id | Facility Snapshot ID | INTEGER | type/PK | Row key. |
| snapshot_date | Snapshot Date | DATE | FK → dim_date.date_id | Snapshot date: the 1st of the month the snapshot describes. Join to the calendar on this date. |
| facility_id | Facility ID | INTEGER |  | Credit facility identifier. Used only for counting distinct facilities; it has no descriptive attributes. |
| customer_id | Customer ID | INTEGER | FK → dim_customer.customer_id | Borrowing client. |
| product_id | Product ID | INTEGER | FK → dim_product.product_id | Facility product (e.g. CRE Term, CRE Bridge, C&I). |
| lob_id | Lob ID | INTEGER | FK → dim_line_of_business.lob_id | Line of business: Commercial Real Estate or Middle Market Lending. |
| risk_rating_id | Risk Rating ID | INTEGER | FK → dim_risk_rating.risk_rating_id | Current regulatory risk rating of the facility. |
| commitment_amount | Commitment Amount | NUMERIC | type/Currency | Committed amount as of the snapshot. Point-in-time: never add across months. |
| outstanding_balance | Outstanding Balance | NUMERIC | type/Currency | Drawn balance as of the snapshot. Point-in-time: never add across months. |
| undrawn_amount | Undrawn Amount | NUMERIC | type/Currency | Undrawn availability as of the snapshot. Point-in-time: never add across months. |
| interest_income_mtd | Interest Income | NUMERIC | type/Currency | Interest income for the month (flow). |
| nim_bps | Net Interest Margin (bps) | FLOAT | type/Score | Net interest margin in basis points. A ratio: average it, never add it. |
| is_nonperforming | Is Nonperforming | BOOLEAN | type/Category | True when the facility is non-performing in that month. |

### Consumer Loan Originations (`fact_loan_origination`, 200,000 rows)

Consumer Lending line of business. One row per consumer loan booked (mortgage, home equity, indirect auto, specialty). The loan is dated by its origination date. Delinquency status and current balance are as of the latest month (June 2026), not a monthly history.

Metabase entity type: `entity/TransactionTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| loan_id | Loan ID | INTEGER | type/PK | Loan key. |
| origination_date | Origination Date | DATE | FK → dim_date.date_id | Date the loan was booked. Join to the calendar on this date. |
| customer_id | Customer ID | INTEGER | FK → dim_customer.customer_id | Borrower. |
| branch_id | Branch ID | INTEGER | FK → dim_branch.branch_id | Originating branch. Use this (via Branch > Market) for geography. |
| market_id | Market ID | INTEGER |  | Denormalized copy of the branch's market. Do not join on it; use branch_id for geography. |
| product_id | Product ID | INTEGER | FK → dim_product.product_id | Loan product. |
| loan_amount | Loan Amount | NUMERIC | type/Currency | Originated principal. |
| current_balance | Current Balance | NUMERIC | type/Currency | Outstanding balance as of the latest month. |
| interest_rate_pct | Interest Rate Pct | FLOAT | type/Percentage | Note rate in percentage points (6.40 means 6.4%). |
| term_months | Term Months | INTEGER |  | Loan term in months. |
| fico_band | Fico Band | STRING | type/Category | Borrower FICO band at origination. |
| ltv | Ltv | FLOAT | type/Percentage | Loan-to-value ratio at origination. |
| vintage | Vintage | STRING | type/Category | Origination month (YYYY-MM), used for vintage analysis. |
| delinquency_status | Delinquency Status | STRING | type/Category | Current, 30 DPD, 60 DPD, or 90+ DPD (days past due), as of the latest month. |
| days_past_due | Days Past Due | INTEGER |  | Days past due as of the latest month. |

### Commercial Payments (monthly) (`fact_payment_transaction`, 538,223 rows)

Commercial Payments (treasury management) line of business. One row per commercial client x payments product x month. All amounts are monthly flows and add up over time.

Metabase entity type: `entity/TransactionTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| payment_id | Payment ID | INTEGER | type/PK | Row key. |
| activity_month | Activity Month | DATE | FK → dim_date.date_id | First day of the activity month. Join to the calendar on this date. |
| customer_id | Customer ID | INTEGER | FK → dim_customer.customer_id | Commercial client. |
| product_id | Product ID | INTEGER | FK → dim_product.product_id | Payments product (ACH, Wire, RTP, Card, Liquidity, FX, ...). |
| transaction_count | Transaction Count | INTEGER | type/Quantity | Number of payment transactions in the month. |
| payment_volume_usd | Payment Volume | NUMERIC | type/Currency | Dollar volume processed in the month. |
| fee_revenue_usd | Fee Revenue | NUMERIC | type/Currency | Fee revenue earned in the month. |

### Branch (`dim_branch`, 1,000 rows)

About 1,000 branches. Each branch belongs to one market; geography (state, region) should be taken from the Market table via market_id so all facts roll up the same way. Hierarchy: Region > State > Market > Branch.

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| branch_id | Branch ID | INTEGER | type/PK | Branch key. |
| branch_name | Branch | STRING | type/Name | Branch name. Lowest level of branch geography. |
| branch_type | Branch Type | STRING | type/Category | Branch format: Financial Center, In-Store, or Private Bank Office. An attribute of the branch, not a hierarchy level. |
| market_id | Market ID | INTEGER | FK → dim_market.market_id | The market this branch belongs to. |
| state | State | STRING | type/State | Denormalized copy of the market's state. Prefer Market.state. |
| region | Region | STRING | type/Category | Denormalized copy of the market's region. Prefer Market.region. |

### Customer (`dim_customer`, 58,000 rows)

58,000 customers: 50,000 consumer and 8,000 commercial clients. Hierarchies: Customer Type > Customer Segment > Customer; Industry Vertical (commercial only); Customer Region > Customer State. Customer region is where the customer is located and is separate from branch region.

Metabase entity type: `entity/UserTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| customer_id | Customer ID | INTEGER | type/PK | Customer key. |
| customer_key | Customer Key | STRING |  | Business customer key, an attribute of the customer. |
| customer_name | Customer | STRING | type/Name | Customer or client name. Lowest level of the customer hierarchy. |
| customer_type | Customer Type | STRING | type/Category | Consumer or Commercial. Top of the customer hierarchy. |
| segment | Customer Segment | STRING | type/Category | Customer segment. Consumer: Mass Market, Mass Affluent, Private / HNW, Small Business. Commercial: Middle Market, Corporate, Institutional. |
| industry_vertical | Industry Vertical | STRING | type/Category | Industry of commercial clients: Healthcare, Technology, Real Estate, Energy, Industrial, Public Sector, Consumer. 'N/A' for consumer customers. |
| revenue_band | Revenue Band | STRING | type/Category | Commercial client revenue band, an attribute of the customer. 'N/A' for consumers. |
| region | Customer Region | STRING | type/Category | Region where the customer is located. |
| state | Customer State | STRING | type/State | State where the customer is located. Child of customer region. |
| acquisition_date | Acquisition Date | DATE |  | Date the customer relationship started. |

### Calendar (`dim_date`, 1,096 rows)

Conformed calendar, one row per day from 2023-07-01 to 2026-06-30. Shared by all four fact tables as the single time axis. Calendar hierarchy: Year > Quarter > Month > Day (fiscal year = calendar year). Deposit and facility snapshots are dated the 1st of each month.

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| date_id | Date | DATE | type/PK | Calendar day. Lowest level of the calendar hierarchy. |
| day_of_week | Day Of Week | INTEGER |  | Day of week number (1-7). |
| day_name | Day Name | STRING | type/Category | Day of week name (Monday..Sunday). |
| day_of_month | Day Of Month | INTEGER |  | Day of month (1-31). |
| month_num | Month Num | INTEGER |  | Month number within the year (1-12). |
| month_name | Month Name | STRING | type/Category | Month name (January..December). |
| year_month | Month | STRING | type/Category | Year-qualified month label, format YYYY-MM (e.g. 2025-03). Month level of the calendar hierarchy; unique across years. |
| quarter_num | Quarter Num | INTEGER |  | Quarter number within the year (1-4). |
| quarter_name | Quarter | STRING | type/Category | Year-qualified quarter label, format 'Qn YYYY' (e.g. 'Q1 2025'). Quarter level of the calendar hierarchy. Sort chronologically by year then quarter number, not alphabetically. |
| year_num | Year | INTEGER | type/Category | Calendar year. Top level of the calendar hierarchy. 2023 and 2026 are partial years in this data (Jul-Dec 2023, Jan-Jun 2026). |
| is_weekend | Is Weekend | BOOLEAN |  | True for Saturday and Sunday. |
| is_month_end | Is Month End | BOOLEAN |  | True on the last day of each month. Note: deposit and facility snapshots are dated the 1st of the month, not month-end. |

### Line of Business (`dim_line_of_business`, 5 rows)

The bank's lines of business. Hierarchy: Segment (Consumer Bank / Commercial Bank) > Line of Business (Retail Deposits, Consumer Lending, Commercial Payments, Commercial Real Estate, Middle Market Lending).

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| lob_id | Lob ID | INTEGER | type/PK | Line of business key. |
| lob_name | Line of Business | STRING | type/Name | Line of business name. |
| segment | Bank Segment | STRING | type/Category | Bank segment: Consumer Bank or Commercial Bank. Parent of line of business. |

### Market (`dim_market`, 30 rows)

Metro markets in the bank's 15-state footprint. Branch geography hierarchy: Region > State > Market > Branch (Branch comes from the Branch table, which points to its market).

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| market_id | Market ID | INTEGER | type/PK | Market key. |
| market_name | Market | STRING | type/City | Metro market name. |
| state | State | STRING | type/State | US state of the market. |
| region | Region | STRING | type/Category | Geographic region: Great Lakes, Northeast, Pacific, Rocky Mountains. Top of the branch geography hierarchy. |

### Product (`dim_product`, 24 rows)

24 banking products across all four lines of business. Hierarchy: Product Line of Business > Product Category > Product.

Metabase entity type: `entity/ProductTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| product_id | Product ID | INTEGER | type/PK | Product key. |
| product_name | Product | STRING | type/Name | Product name (24 products, e.g. HELOC). |
| product_category | Product Category | STRING | type/Category | Product category (18 values), for example Checking, Mortgage, Home Equity, Auto, ACH, RTP, Card, Liquidity, FX, CRE, C&I. |
| line_of_business | Product Line of Business | STRING | type/Category | Line of business the product belongs to. Top of the product hierarchy. |
| lob_id | Lob ID | INTEGER | FK → dim_line_of_business.lob_id | Line of business key for the product. |

### Risk Rating (`dim_risk_rating`, 5 rows)

Regulatory credit risk ratings for commercial facilities. Hierarchy: Regulatory Class (Pass / Criticized / Classified) > Rating Grade.

Metabase entity type: `entity/GenericTable`

| Column | Display name | Type | Role | Description |
|---|---|---|---|---|
| risk_rating_id | Risk Rating ID | INTEGER | type/PK | Risk rating key. |
| rating_grade | Rating Grade | STRING | type/Category | Regulatory rating grade: 1-3 Strong, 4-6 Acceptable, 7 Special Mention, 8 Substandard, 9 Doubtful. |
| regulatory_class | Regulatory Class | STRING | type/Category | Regulatory classification: Pass, Criticized, or Classified. Parent of rating grade. |
| is_nonperforming | Is Nonperforming Grade | BOOLEAN | type/Category | True for grades considered non-performing. |

## Metrics

Each metric is a Metabase Metric in a line-of-business sub-collection of the Business Catalog. The definition is the SQL-like formula the metric states; the description carries the business rules.

### Commitment Amount

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `SUM(commitment_amount)`
- **Business rules:** Committed facility amount. Definition: SUM(commitment_amount). Rule: point-in-time; take the latest monthly snapshot in the period, add across facilities, never across months.

### Facility Count

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `COUNT(DISTINCT facility_id)`
- **Business rules:** Number of distinct credit facilities. Definition: COUNT(DISTINCT facility_id).

### Interest Income

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `SUM(interest_income_mtd)`
- **Business rules:** Interest income earned on facilities. Definition: SUM(interest_income_mtd). Adds up over time.

### NPL Ratio

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `Nonperforming Balance / Outstanding Balance, both read from the latest monthly snapshot in the period`
- **Business rules:** Non-performing loan ratio. Definition: Nonperforming Balance / Outstanding Balance, both read from the latest monthly snapshot in the period. Ratio: compute from the balances, never average the ratios.

### Net Interest Margin (bps)

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `AVG(nim_bps)`
- **Business rules:** Net interest margin in basis points. Definition: AVG(nim_bps). A ratio: average it, never add it.

### Nonperforming Balance

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `SUM(outstanding_balance) WHERE is_nonperforming = true`
- **Business rules:** Outstanding balance on non-performing facilities. Definition: SUM(outstanding_balance) WHERE is_nonperforming = true. Rule: point-in-time; take the latest monthly snapshot in the period, never add across months.

### Outstanding Balance

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `SUM(outstanding_balance)`
- **Business rules:** Drawn facility balance. Definition: SUM(outstanding_balance). Rule: point-in-time; take the latest monthly snapshot in the period, add across facilities, never across months. Also report it year-over-year: prior-year value and YoY growth %.

### Undrawn Amount

- **Line of business:** CRE + Middle Market
- **Source table:** `fact_loan_facility_snapshot`
- **Definition:** `SUM(undrawn_amount)`
- **Business rules:** Undrawn facility availability. Definition: SUM(undrawn_amount). Rule: point-in-time; take the latest monthly snapshot in the period, never add across months.

### Active Client Count

- **Line of business:** Commercial Payments
- **Source table:** `fact_payment_transaction`
- **Definition:** `COUNT(DISTINCT customer_id)`
- **Business rules:** Commercial clients with any payments activity in the period. Definition: COUNT(DISTINCT customer_id). Not additive: count distinct clients over the whole period.

### Fee Revenue

- **Line of business:** Commercial Payments
- **Source table:** `fact_payment_transaction`
- **Definition:** `SUM(fee_revenue_usd)`
- **Business rules:** Treasury-management and payments fee revenue. Definition: SUM(fee_revenue_usd). Adds up over time. Also report: year-to-date (sum from the start of the calendar year through the period), prior-year value (same period one year earlier), and YoY growth % = (this period - same period last year) / same period last year.

### Payment Volume

- **Line of business:** Commercial Payments
- **Source table:** `fact_payment_transaction`
- **Definition:** `SUM(payment_volume_usd)`
- **Business rules:** Dollar volume of payments processed. Definition: SUM(payment_volume_usd). Adds up over time.

### Transaction Count

- **Line of business:** Commercial Payments
- **Source table:** `fact_payment_transaction`
- **Definition:** `SUM(transaction_count)`
- **Business rules:** Number of payment transactions. Definition: SUM(transaction_count). Adds up over time.

### 30 DPD Loan Count

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `COUNT of loans WHERE delinquency_status = '30 DPD'`
- **Business rules:** Loans currently 30 days past due. Definition: COUNT of loans WHERE delinquency_status = '30 DPD'.

### 60 DPD Loan Count

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `COUNT of loans WHERE delinquency_status = '60 DPD'`
- **Business rules:** Loans currently 60 days past due. Definition: COUNT of loans WHERE delinquency_status = '60 DPD'.

### 90+ DPD Loan Count

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `COUNT of loans WHERE delinquency_status = '90+ DPD'`
- **Business rules:** Loans currently 90 or more days past due. Definition: COUNT of loans WHERE delinquency_status = '90+ DPD'.

### 90+ DPD Rate

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `90+ DPD Loan Count / Loan Count`
- **Business rules:** Share of loans 90+ days past due. Definition: 90+ DPD Loan Count / Loan Count. Ratio: compute from the totals.

### Any-DPD Rate

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `Delinquent Loan Count / Loan Count, i.e. COUNT(WHERE delinquency_status <> 'Current') / COUNT(*)`
- **Business rules:** Share of loans currently past due. Definition: Delinquent Loan Count / Loan Count, i.e. COUNT(WHERE delinquency_status <> 'Current') / COUNT(*). Ratio: compute from the totals, never average the rates.

### Average Interest Rate

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `AVG(interest_rate_pct)`
- **Business rules:** Average note rate in percentage points (6.40 = 6.4%). Definition: AVG(interest_rate_pct).

### Average LTV

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `AVG(ltv)`
- **Business rules:** Average loan-to-value ratio. Definition: AVG(ltv).

### Average Loan Size

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `Loan Amount Originated / Loan Count`
- **Business rules:** Average originated principal per loan. Definition: Loan Amount Originated / Loan Count. Ratio: compute from the totals.

### Current Loan Balance

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `SUM(current_balance)`
- **Business rules:** Outstanding balance of originated loans as of the latest month. Definition: SUM(current_balance).

### Delinquent Loan Count

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `COUNT of loans WHERE delinquency_status <> 'Current'`
- **Business rules:** Loans currently past due (30, 60 or 90+ days). Definition: COUNT of loans WHERE delinquency_status <> 'Current'.

### Loan Amount Originated

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `SUM(loan_amount), dated by origination date`
- **Business rules:** Principal of consumer loans booked in the period. Definition: SUM(loan_amount), dated by origination date. Adds up over time. Also report it year-over-year: prior-year value and YoY growth % = (this period - same period last year) / same period last year.

### Loan Count

- **Line of business:** Consumer Lending
- **Source table:** `fact_loan_origination`
- **Definition:** `COUNT(loan_id)`
- **Business rules:** Number of consumer loans booked. Definition: COUNT(loan_id).

### Accounts Closed

- **Line of business:** Retail Deposits
- **Source table:** `fact_deposit_snapshot`
- **Definition:** `SUM(accounts_closed)`
- **Business rules:** Deposit accounts closed in the period (attrition). Definition: SUM(accounts_closed). Adds up over time.

### Accounts Opened

- **Line of business:** Retail Deposits
- **Source table:** `fact_deposit_snapshot`
- **Definition:** `SUM(accounts_opened)`
- **Business rules:** Deposit accounts opened in the period. Definition: SUM(accounts_opened). Adds up over time.

### Average Daily Balance

- **Line of business:** Retail Deposits
- **Source table:** `fact_deposit_snapshot`
- **Definition:** `SUM(avg_daily_balance)`
- **Business rules:** Average daily deposit balance for the month. Definition: SUM(avg_daily_balance). Rule: point-in-time; take the latest monthly snapshot in the period, never add across months.

### Deposit Account Count

- **Line of business:** Retail Deposits
- **Source table:** `fact_deposit_snapshot`
- **Definition:** `SUM(account_count)`
- **Business rules:** Open deposit accounts. Definition: SUM(account_count). Rule: point-in-time; take the latest monthly snapshot in the period, never add across months.

### EOM Balance

- **Line of business:** Retail Deposits
- **Source table:** `fact_deposit_snapshot`
- **Definition:** `SUM(eom_balance)`
- **Business rules:** Total end-of-month deposit balance. Definition: SUM(eom_balance). Rule: point-in-time balance. For any period (quarter, year), take the balance from the latest monthly snapshot in that period; add across branches, products and segments, never across months. Also report it year-over-year: prior-year value and YoY growth % = (this period - same period last year) / same period last year.

### Interest Expense

- **Line of business:** Retail Deposits
- **Source table:** `fact_deposit_snapshot`
- **Definition:** `SUM(interest_expense_mtd)`
- **Business rules:** Interest paid on deposits. Definition: SUM(interest_expense_mtd). Adds up over time.
