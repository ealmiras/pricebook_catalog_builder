create or replace view export_base_pricebook_pretty as
select
    sku,
    brand,
    region,
    currency,

    round(base_price::numeric, 2) as base_price,
    round(net_price::numeric, 2) as net_price,
    round(cost_local::numeric, 2) as cost_local,

    round(margin_pct::numeric, 4) as margin_pct,
    pricing_status,

    case
        when pricing_status = 'FAIL' then 'BELOW_MIN_MARGIN'
        else null
    end as fail_reason,

    run_timestamp
from (
    select
        sku,
        brand,
        region,
        currency,
        base_price,
        net_price,
        cost_local,
        margin_pct,
        pricing_status,
        run_timestamp
    from (
        -- Use your canonical output (recommended: final_margin_output)
        select
            sku,
            brand,
            region,
            currency,
            base_price,
            net_price,
            cost_local,
            margin_pct,
            pricing_status,
            current_timestamp as run_timestamp
        from final_margin_output
    ) t
) x
order by sku, region;
