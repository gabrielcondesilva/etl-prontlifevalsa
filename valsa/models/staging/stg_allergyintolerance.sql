with source as (
    select * from {{ source('prontlife', 'allergyintolerance') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as allergy_id,

        -- paciente
        replace(data -> 'patient' ->> 'reference', 'Patient/', '')         as patient_id,
        data -> 'patient' ->> 'display'                                     as patient_name,
        (
            select ext ->> 'valueCode'
            from jsonb_array_elements(data -> 'patient' -> 'extension') as ext
            where ext ->> 'url' = 'urn:userType'
            limit 1
        )                                                                   as patient_user_type,

        -- recorder (pode ser Practitioner ou Patient)
        split_part(data -> 'recorder' ->> 'reference', '/', 2)             as recorder_id,
        split_part(data -> 'recorder' ->> 'reference', '/', 1)             as recorder_type,
        data -> 'recorder' ->> 'display'                                    as recorder_name,

        -- atendimento
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,

        -- tipo (alergia ou intolerância)
        data ->> 'type'                                                     as allergy_type,

        -- substância
        data -> 'code' ->> 'text'                                           as substance_name,
        data -> 'code' -> 'coding' -> 0 ->> 'code'                         as substance_code,
        data -> 'code' -> 'coding' -> 0 ->> 'system'                       as substance_system,
        data -> 'code' -> 'coding' -> 0 ->> 'display'                      as substance_display,

        -- status clínico e verificação
        data -> 'clinicalStatus' -> 'coding' -> 0 ->> 'code'               as clinical_status,
        data -> 'verificationStatus' -> 'coding' -> 0 ->> 'code'           as verification_status,

        -- data de registro
        (data ->> 'recordedDate')::timestamptz                             as recorded_date,

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
