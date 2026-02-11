create or replace view export_platform_pricebook_wide as
select
    sku,

    -- Base prices by region (only OK rows; FAIL becomes NULL)
    max(base_price) filter (where region = 'EU_DE' and pricing_status = 'OK') as eu_de,
    max(base_price) filter (where region = 'UK'    and pricing_status = 'OK') as uk,
    max(base_price) filter (where region = 'US'    and pricing_status = 'OK') as us,
    max(base_price) filter (where region = 'JP'    and pricing_status = 'OK') as jp,
    max(base_price) filter (where region = 'UAE'   and pricing_status = 'OK') as uae,

    -- Optional: quality flags (handy for platform uploads)
    bool_or(pricing_status = 'FAIL') as has_any_fail,
    string_agg(distinct region, ', ' order by region)
        filter (where pricing_status = 'FAIL') as failed_regions,

    current_timestamp as run_timestamp
from export_base_pricebook_pretty
group by sku
order by sku;
