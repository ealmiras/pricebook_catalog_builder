create or replace view int_margin_checks as (
    with prices as (
        select * from int_rrp_with_fallback
    ),

    tax as (
        select * from tax_rules
    ),

    fx as (
        select distinct on (to_ccy)
            to_ccy,
            rate
        from fx_rates
        where from_ccy = 'EUR'
        order by to_ccy, updated_at desc
    )

    select
        p.*,

        case
            when t.vat_included_in_price = true
                then p.base_price / (1 + t.vat_rate)
            else p.base_price
        end as net_price,

        (p.unit_cost_eur *
            case when p.currency = 'EUR'
                then 1
                else fx.rate
            end
        ) as cost_local

    from prices p
    join tax t on t.region = p.region
    left join fx on fx.to_ccy = p.currency
);
