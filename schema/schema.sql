-- ========================
-- RAW INPUT
-- ========================

create table raw_po (
    po_id text,
    sku text,
    brand text,
    po_date date,
    updated_at timestamp,
    unit_cost_eur numeric(6,2),

    rrp_eur numeric(6,2),
    rrp_uk_gbp numeric(6,2),
    rrp_us_usd numeric(6,2),
    rrp_uae_aed numeric(6,2),
    rrp_jp_jpy numeric(6,0)
);

-- ========================
-- DIMENSIONS / POLICY
-- ========================

create table dim_regions (
    region text primary key,
    currency text
);

create table fx_rates (
    from_ccy text,
    to_ccy text,
    rate numeric(6,4),
    updated_at timestamp
);

create table tax_rules (
    region text primary key,
    vat_rate numeric(6,4),
    vat_included_in_price boolean
);

create table pricing_guardrails (
    region text primary key,
    min_margin_pct numeric(6,4)
);

-- ========================
-- OUTPUT TABLES
-- ========================

create table mart_base_pricebook (
    sku text,
    brand text,
    region text,
    currency text,
    base_price numeric(6,2),
    net_price numeric(6,2),
    margin_pct numeric(6,4),
    pricing_status text,
    run_timestamp timestamp default current_timestamp
);

create table mart_price_history_scd2 (
    sku text,
    region text,
    base_price numeric(6,2),
    valid_from timestamp,
    valid_to timestamp,
    is_current boolean
);
