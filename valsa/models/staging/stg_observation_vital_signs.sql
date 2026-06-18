with source as (
    select * from {{ source('prontlife', 'observation') }}
),

vital_signs as (
    select *
    from source
    where data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code' = 'vital-signs'
),

renamed as (
    select
        -- chaves
        id                                                                  as observation_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,
        split_part(data -> 'performer' -> 0 ->> 'reference', '/', 2)       as performer_id,
        split_part(data -> 'performer' -> 0 ->> 'reference', '/', 1)       as performer_type,
        data -> 'performer' -> 0 ->> 'display'                             as performer_name,

        -- tipo de medida
        data -> 'code' -> 'coding' -> 0 ->> 'code'                         as measure_code,
        data -> 'code' -> 'coding' -> 0 ->> 'display'                      as measure_name,

        -- valor simples (valueQuantity — maioria dos sinais vitais)
        (data -> 'valueQuantity' ->> 'value')::numeric                     as value,
        data -> 'valueQuantity' ->> 'unit'                                  as unit,

        -- pressão arterial (component[] — pivotado)
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = '8480-6'
            limit 1
        )                                                                   as systolic_bp,
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = '8462-4'
            limit 1
        )                                                                   as diastolic_bp,
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = '8478-0'
            limit 1
        )                                                                   as mean_bp,
        (
            select comp -> 'valueQuantity' ->> 'unit'
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = '8480-6'
            limit 1
        )                                                                   as bp_unit,

        -- status e datas
        data ->> 'status'                                                   as status,
        (data ->> 'issued')::timestamptz                                    as issued,
        (data ->> 'effectiveDateTime')::timestamptz                         as effective_datetime,

        -- metadados
        delivery_date,
        ingested_at

    from vital_signs
)

select * from renamed
