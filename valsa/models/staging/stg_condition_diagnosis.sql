with source as (
    select * from {{ source('prontlife', 'condition_diagnosis') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as condition_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,

        -- recorder (pode ser Practitioner ou Patient)
        split_part(data -> 'recorder' ->> 'reference', '/', 2)             as recorder_id,
        split_part(data -> 'recorder' ->> 'reference', '/', 1)             as recorder_reference_type,
        data -> 'recorder' ->> 'display'                                    as recorder_name,

        -- asserter (pode ser Practitioner ou Patient)
        split_part(data -> 'asserter' ->> 'reference', '/', 2)             as asserter_id,
        split_part(data -> 'asserter' ->> 'reference', '/', 1)             as asserter_reference_type,
        data -> 'asserter' ->> 'display'                                    as asserter_name,
        data -> 'asserter' ->> 'type'                                       as asserter_type,

        -- diagnóstico (CID-10)
        data -> 'code' ->> 'text'                                           as diagnosis_name,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%cid-10%'
               or item ->> 'system' like '%comorbidades%'
            limit 1
        )                                                                   as cid10_internal_code,
        (
            select item ->> 'display'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%cid-10%'
               or item ->> 'system' like '%comorbidades%'
            limit 1
        )                                                                   as cid10_display,

        -- categoria
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'               as category_code,
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'display'             as category_display,

        -- status clínico e verificação
        data -> 'clinicalStatus' -> 'coding' -> 0 ->> 'code'               as clinical_status,
        data -> 'verificationStatus' -> 'coding' -> 0 ->> 'code'           as verification_status,

        -- observação
        data -> 'note' -> 0 ->> 'text'                                     as note,

        -- data de registro
        (data ->> 'recordedDate')::timestamptz                             as recorded_date,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
