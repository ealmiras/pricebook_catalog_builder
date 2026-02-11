#!/usr/bin/env bash
set -euo pipefail

CONTAINER="pricing_portfolio_pg"
DB="pricing_portfolio"
USER="postgres"

RUN_DATE="$(date +%F)"   # YYYY-MM-DD
EXPORT_DIR="/workspace/data/exports"

echo "==> Starting Docker services..."
docker compose up -d

echo "==> Waiting for Postgres to be ready..."
until docker exec "$CONTAINER" pg_isready -U "$USER" -d "$DB" >/dev/null 2>&1; do
  sleep 1
done

echo "==> Running schema..."
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < schema/schema.sql

echo "==> Loading seeds..."
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" -c "truncate raw_po, dim_regions, fx_rates, tax_rules, pricing_guardrails;"

docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" -c "\copy raw_po FROM '/workspace/data/raw_po.csv' CSV HEADER;"
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" -c "\copy dim_regions FROM '/workspace/data/dim_regions.csv' CSV HEADER;"
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" -c "\copy fx_rates FROM '/workspace/data/fx_rates.csv' CSV HEADER;"
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" -c "\copy tax_rules FROM '/workspace/data/tax_rules.csv' CSV HEADER;"
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" -c "\copy pricing_guardrails FROM '/workspace/data/pricing_guardrails.csv' CSV HEADER;"

echo "==> Building pipeline views..."
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/01_staging/stg_po_latest.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/01_staging/stg_rrp_long.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/02_intermediate/int_rrp_with_fallback.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/02_intermediate/int_margin_checks.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/03_marts/final_margin_output.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/03_marts/mart_base_pricebook.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/03_marts/mart_price_history_scd2.sql

echo "==> Creating export views..."
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/04_exports/export_base_pricebook.sql
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" < sql/04_exports/export_platform_pricebook_wide.sql

echo "==> Exporting CSVs to data/exports/..."
docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" \
  -c "\copy (select * from export_base_pricebook_pretty order by sku, region) to '${EXPORT_DIR}/base_pricebook_${RUN_DATE}.csv' csv header;"

docker exec -i "$CONTAINER" psql -U "$USER" -d "$DB" \
  -c "\copy (select sku, eu_de, uk, us, jp, uae, has_any_fail, failed_regions, run_timestamp from export_platform_pricebook_wide order by sku) to '${EXPORT_DIR}/platform_pricebook_wide_${RUN_DATE}.csv' csv header;"

echo "==> Done."
echo "Outputs:"
echo "  data/exports/base_pricebook_${RUN_DATE}.csv"
echo "  data/exports/platform_pricebook_wide_${RUN_DATE}.csv"
