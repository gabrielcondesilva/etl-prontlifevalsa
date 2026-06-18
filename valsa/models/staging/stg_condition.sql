with source as (
    select * from {{ source('prontlife', 'condition') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as condition_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,
        replace(data -> 'recorder' ->> 'reference', 'Practitioner/', '')   as recorder_id,
        data -> 'recorder' ->> 'display'                                    as recorder_name,
        replace(data -> 'asserter' ->> 'reference', 'Practitioner/', '')   as asserter_id,
        data -> 'asserter' ->> 'display'                                    as asserter_name,
        data -> 'asserter' ->> 'type'                                       as asserter_type,

        -- diagnóstico
        data -> 'code' ->> 'text'                                           as diagnosis_name,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%cid-10%'
               or item ->> 'system' like '%comorbidades%'
            limit 1
        )                                                                   as cid10_code,
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

        -- gravidade (só no HPP)
        data -> 'severity' -> 'coding' -> 0 ->> 'code'                     as severity_code,
        data -> 'severity' -> 'coding' -> 0 ->> 'display'                  as severity_display,

        -- status clínico e verificação
        data -> 'clinicalStatus' -> 'coding' -> 0 ->> 'code'               as clinical_status,
        data -> 'verificationStatus' -> 'coding' -> 0 ->> 'code'           as verification_status,

        -- datas
        (data ->> 'recordedDate')::timestamptz                             as recorded_date,
        (data ->> 'onsetDateTime')::timestamptz                            as onset_datetime,

        -- observação (primeira nota)
        data -> 'note' -> 0 ->> 'text'                                     as note_text,
        (data -> 'note' -> 0 ->> 'time')::timestamptz                      as note_time,
        replace(
            data -> 'note' -> 0 -> 'authorReference' ->> 'reference',
            'Practitioner/', ''
        )                                                                   as note_author_id,
        data -> 'note' -> 0 -> 'authorReference' ->> 'display'             as note_author_name,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
