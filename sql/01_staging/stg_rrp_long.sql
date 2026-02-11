create or replace view stg_rrp_long as (
    with latest as (
        select * from stg_po_latest
    )

    select sku, brand, unit_cost_eur,
        'EU_DE' as region,
        'EUR' as currency,
        rrp_eur as rrp_local,
        rrp_eur
    from latest

    union all

    select sku, brand, unit_cost_eur,
        'UK',
        'GBP',
        rrp_uk_gbp,
        rrp_eur
    from latest

    union all

    select sku, brand, unit_cost_eur,
        'US',
        'USD',
        rrp_us_usd,
        rrp_eur
    from latest

    union all

    select sku, brand, unit_cost_eur,
        'UAE',
        'AED',
        rrp_uae_aed,
        rrp_eur
    from latest

    union all

    select sku, brand, unit_cost_eur,
        'JP',
        'JPY',
        rrp_jp_jpy,
        rrp_eur
    from latest
);
