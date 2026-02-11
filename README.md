# Global Base Pricebook Catalog Builder (SQL + Docker)

A reproducible, policy-driven pricing engine built with PostgreSQL and Docker, that generates region-specific base pricebooks from PO-level RRPs, applying VAT logic, FX conversion, and margin guardrails.

## Objective

Automate base price and catalog creation to:
- Eliminate manual spreadsheet-based pricing
- Enforce consistent pricing policy across regions
- Validate margin thresholds before release
- Provide clean exports for downstream platforms (e.g. Salesforce)

Base prices are derived from RRP inputs.  
If a regional RRP is missing, the system falls back to the EUR RRP converted via FX.

## Regions Covered
- EU_DE (EUR)  
- UK (GBP)  
- US (USD)  
- UAE (AED)  
- JP (JPY)

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

## Architecture Diagram
```
                    ┌─────────────────────────────┐
                    │          Seed Inputs        │
                    │                             │
                    │ data/raw_po.csv             │
                    │ data/fx_rates.csv           │
                    │ data/tax_rules.csv          │
                    │ data/pricing_guardrails.csv │
                    └───────────────┬─────────────┘
                                    v
┌──────────────────────────────────────────────────────────────────────┐
│                               01_staging                             │
│                                                                      │
│  stg_po_latest:    latest PO per SKU (window function)               │
│  stg_rrp_long:     wide RRPs → long format (SKU × Region)            │
└───────────────────────────────────┬──────────────────────────────────┘
                                    v
┌──────────────────────────────────────────────────────────────────────┐
│                           02_intermediate                            │
│                                                                      │
│  int_rrp_with_fallback:  use local RRP else EUR × FX                 │
│  int_margin_checks:      VAT netting + cost conversion + margin calc │
└───────────────────────────────────┬──────────────────────────────────┘
                                    v
┌──────────────────────────────────────────────────────────────────────┐
│                               03_marts                               │
│                                                                      │
│  final_margin_output:   apply region min margin guardrails → OK/FAIL │
│  mart_base_pricebook:   persisted base pricebook output              │
│  mart_price_history_scd2: SCD2 history (valid_from/to, is_current)   │
└───────────────────────────────────┬──────────────────────────────────┘
                                    v
┌──────────────────────────────────────────────────────────────────────┐
│                               04_exports                             │
│                                                                      │
│  export_base_pricebook_pretty: detailed QA output + failure reasons  │
│  export_platform_pricebook_wide: wide SKU export (platform upload)   │
│                                                                      │
│  CSVs written to: data/exports/*_<YYYY-MM-DD>.csv                    │
└──────────────────────────────────────────────────────────────────────┘
```

The pipeline follows an analytics-engineering pattern (staging → intermediate → marts → exports) while remaining runnable end-to-end via Docker.

## Quick Start (Reproducible Execution)
**Requirements:**
- Docker Desktop
- Make (optional but recommended)

Run the entire system with:
```
make run
```

The pipeline is idempotent and safe to rerun — existing tables are dropped and recreated during execution.

**This will:**
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

## Design Decisions
- **RRP-first architecture**: Base prices are derived from recommended retail prices, not cost-plus logic. Cost is used strictly for margin validation.
- **Wide-to-long normalization**: RRPs are converted from wide format (one column per region) into a normalized long structure to enable scalable region logic.
- **High-precision FX storage**: FX rates use high precision numeric types to support currencies with large magnitude (e.g. JPY).
- **Fail-safe export design**: Platform upload export excludes prices that violate margin guardrails (NULL instead of invalid price).
- **Layered SQL structure**: Staging → Intermediate → Marts → Exports mirrors analytics engineering best practices.

## Technologies
- PostgreSQL
- Docker
- Makefile automation

## Why This Project

This project demonstrates the ability to design and productionize pricing logic in a structured analytics engineering workflow.

It highlights:

- Translating business pricing policy into modular SQL logic
- Designing region-aware financial calculations (VAT, FX, margin)
- Implementing guardrails to prevent invalid commercial decisions
- Building reproducible, containerized data pipelines
- Generating platform-ready export artifacts
