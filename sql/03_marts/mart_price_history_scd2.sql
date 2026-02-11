-- Close existing records
update mart_price_history_scd2 h
set valid_to = current_timestamp,
    is_current = false
from mart_base_pricebook m
where h.sku = m.sku
  and h.region = m.region
  and h.is_current = true
  and h.base_price <> m.base_price;

-- Insert new current records
insert into mart_price_history_scd2 (
    sku, region, base_price,
    valid_from, valid_to, is_current
)
select
    sku,
    region,
    base_price,
    current_timestamp,
    null,
    true
from mart_base_pricebook;
