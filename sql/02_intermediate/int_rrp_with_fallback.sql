create or replace view int_rrp_with_fallback as (
    with base as (
        select * from stg_rrp_long
    ),

    fx as (
        select distinct on (to_ccy)
            from_ccy,
            to_ccy,
            rate
        from fx_rates
        where from_ccy = 'EUR'
        order by to_ccy, updated_at desc
    )

    select
        b.sku,
        b.brand,
        b.region,
        b.currency,
        b.unit_cost_eur,
        coalesce(
            b.rrp_local,
            b.rrp_eur * fx.rate
        ) as base_price
    from base b
    left join fx
        on fx.to_ccy = b.currency
        and b.region <> 'EU_DE'
);
