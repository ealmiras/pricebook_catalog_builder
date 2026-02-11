# Global Base Pricebook & Catalog Builder (SQL)

**Goal:** automate base price and catalog creation to remove manual errors and enforce consistent pricing policy across regions.
Base prices are RRP-driven; downstream discounted pricebooks are out of scope.

Regions covered: EU-DE, UK, US, UAE, JP

## Pipeline
raw_po_rrp + raw_costs  
→ stg_po_rrp_latest  
→ stg_rrp_long  
→ int_rrp_with_fallback (EUR RRP fallback via FX)  
→ int_margin_checks (VAT/duties normalization + min margin guardrail)  
→ mart_base_pricebook  
→ mart_price_history_scd2  
→ export_pricebook_incremental  

## Key rules
- RRP-first: use local RRP if available, else fallback to EUR RRP × FX
- VAT handling per region (gross vs net)
- Duties handling configurable (included vs add-on)
- Min margin threshold enforcement (validation output)

## How to load?
```
\copy raw_po FROM 'data/raw_po.csv' CSV HEADER;  
\copy dim_regions FROM 'data/dim_regions.csv' CSV HEADER;  
\copy fx_rates FROM 'data/fx_rates.csv' CSV HEADER;  
\copy tax_rules FROM 'data/tax_rules.csv' CSV HEADER;  
\copy pricing_guardrails FROM 'data/pricing_guardrails.csv' CSV HEADER;  
```

## What this project demonstrates

- Modular SQL modeling (staging → intermediate → marts)
- Policy-driven logic (rules stored in tables, not hardcoded)
- Data quality / exception modeling
- History tracking (SCD2)
- Export/incremental patterns (ETL)