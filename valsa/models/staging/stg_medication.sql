{{ config(enabled=false) }}

with source as (
    select * from {{ source('prontlife', 'medication') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as medication_id,

        -- nome do medicamento
        data -> 'code' ->> 'text'                                           as medication_name,

        -- códigos (múltiplos sistemas)
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%anvisa%'
            limit 1
        )                                                                   as anvisa_code,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%codeSystem/medication%'
            limit 1
        )                                                                   as internal_code,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%tiss%'
            limit 1
        )                                                                   as tiss_code,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%tuss%'
            limit 1
        )                                                                   as tuss_code,

        -- princípio ativo (primeiro do array)
        data -> 'ingredient' -> 0 -> 'itemCodeableConcept'
            -> 'coding' -> 0 ->> 'display'                                  as active_ingredient,

        -- classificação terapêutica (dentro de contained[])
        data -> 'contained' -> 0 -> 'medicineClassification' -> 0
            -> 'classification' -> 0 -> 'coding' -> 0 ->> 'display'        as therapeutic_class,

        -- status
        data ->> 'status'                                                   as status,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
