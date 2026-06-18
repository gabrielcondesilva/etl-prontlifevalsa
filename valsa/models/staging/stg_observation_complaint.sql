with source as (
    select * from {{ source('prontlife', 'observation_complaint') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as observation_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,

        -- performer (objeto direto, não array)
        replace(data -> 'performer' ->> 'reference', 'Practitioner/', '')  as performer_id,
        data -> 'performer' ->> 'display'                                   as performer_name,

        -- queixa
        data -> 'code' -> 'coding' -> 0 ->> 'code'                         as complaint_code,
        data -> 'code' -> 'coding' -> 0 ->> 'system'                       as complaint_system,
        data -> 'code' -> 'coding' -> 0 ->> 'display'                      as complaint_name,

        -- categoria
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'               as category_code,

        -- status e data
        data ->> 'status'                                                   as status,
        (data ->> 'effectiveDateTime')::timestamptz                         as effective_datetime,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
