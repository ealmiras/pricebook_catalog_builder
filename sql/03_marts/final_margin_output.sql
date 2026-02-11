create or replace view final_margin_output as (
    select *,
        (net_price - cost_local) / nullif(net_price,0) as margin_pct,
        case
            when (net_price - cost_local) / nullif(net_price,0)
                    < g.min_margin_pct
            then 'FAIL'
            else 'OK'
        end as pricing_status
    from int_margin_checks i
    join pricing_guardrails g
        on g.region = i.region
);