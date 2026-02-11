create or replace view stg_po_latest as (
    with ranked as (
        select *,
            row_number() over (
                partition by sku
                order by po_date desc
            ) as rn
        from raw_po
    )

    select *
    from ranked
    where rn = 1
);
