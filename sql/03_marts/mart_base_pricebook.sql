insert into mart_base_pricebook (
    sku, brand, region, currency,
    base_price, net_price, margin_pct, pricing_status
)
select
    sku,
    brand,
    region,
    currency,
    base_price,
    net_price,
    margin_pct,
    pricing_status
from final_margin_output;
