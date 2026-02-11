# Global Base Pricebook & Catalog Builder (SQL + Docker)

An end-to-end SQL pipeline that generates region-specific base pricebooks from PO-level RRPs, applying VAT logic, FX conversion, and margin guardrails — with reproducible Docker execution and export-ready outputs.

## Objective

Automate base price and catalog creation to:
- Eliminate manual spreadsheet-based pricing
- Enforce consistent pricing policy across regions
- Validate margin thresholds before release
- Provide clean exports for downstream platforms (e.g. Salesforce)

Base prices are RRP-driven.  
If a regional RRP is missing, the system falls back to the EUR RRP converted via FX.

## Regions Covered
EU_DE (EUR)  
UK (GBP)  
US (USD)  
UAE (AED)  
JP (JPY)

## Pricing Logic Overview
For each SKU × Region:
1. Select latest PO per SKU
2. Normalize RRPs from wide → long format
3. Apply fallback logic:
    - Use regional RRP if present
    - Else: EUR_RRP × FX
4. Apply VAT normalization:
    - If VAT included → derive net price
5. Convert cost to region currency
6. Calculate margin
7. Apply guardrail:
    - Flag as FAIL if below region-specific minimum margin
8. Store SCD2 history
9. Generate export views

## Project Structure
```
├── schema/        → table definitions
├── data/          → seed data + exports
├── sql/
│   ├── 01_staging/
│   ├── 02_intermediate/
│   ├── 03_marts/  
│   └── 04_exports/ 
├── scripts/       → one-command execution  
├── docker-compose.yml  
├── Makefile
└── README.md
```

## Quick Start (Reproducible Execution)
Requirements:
- Docker Desktop
- Make (optional but recommended)

Run the entire system with:
```
make run
```

This will:
- Start Postgres (Docker)
- Run schema
- Load seed data
- Build all pipeline views
- Populate marts
- Generate export CSVs

## Generated Outputs
Located in:
```
data/exports/
```

### 1. Detailed Validation Output
**base_pricebook_<DATE>.csv**

Contains:
- SKU
- Region
- Base price
- Net price
- Margin
- Pricing status
- Failure reason

Used for internal review and pricing QA.

### 2. Platform Upload Export
**platform_pricebook_wide_<DATE>.csv**

Wide format (one row per SKU):  
| sku | eu_de | uk | us | jp | uae |

- Only includes valid prices
- Failed regions return NULL
- Ready for CRM / platform ingestion

## Guardrails

Margin thresholds are region-specific:
- EU_DE: 25%
- UK: 25%
- US: 30%
- UAE: 25%
- JP: 20%

Failures are classified as:  
**BELOW_MIN_MARGIN**

## Data Model Highlights
- Wide-to-long normalization (RRPs)
- Policy-driven VAT handling
- FX rates with high precision
- Region-specific margin enforcement
- SCD2 price history table
- Dockerized reproducibility

## Historical Tracking (SCD2)
**mart_price_history_scd2 stores:**
- SKU
- Region
- Base price
- Valid from / valid to
- Current flag

Ensures pricing reproducibility and auditability.

## Seed Data
Includes:
- Multiple SKUs
- Missing regional RRPs (to test fallback)
- VAT-included and VAT-excluded regions
- Both passing and failing margin cases

## Technologies
- PostgreSQL
- Docker
- Makefile automation

## Why This Project
- This project demonstrates:
- Analytics engineering practices
- Financial modeling awareness
- Multi-currency pricing logic
- Guardrail validation systems
- Reproducible data pipelines