with source as (
    select * from {{ source('prontlife', 'procedure') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as procedure_id,

        -- paciente
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        data -> 'subject' ->> 'display'                                     as patient_name,
        (
            select ext ->> 'valueCode'
            from jsonb_array_elements(data -> 'subject' -> 'extension') as ext
            where ext ->> 'url' = 'urn:userType'
            limit 1
        )                                                                   as patient_user_type,

        -- recorder (pode ser Practitioner ou Patient)
        split_part(data -> 'recorder' ->> 'reference', '/', 2)             as recorder_id,
        split_part(data -> 'recorder' ->> 'reference', '/', 1)             as recorder_type,
        data -> 'recorder' ->> 'display'                                    as recorder_name,

        -- procedimento
        data -> 'code' ->> 'text'                                           as procedure_name,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%prontlife.com.br/'
               or item ->> 'system' = 'https://prontlife.com.br'
            limit 1
        )                                                                   as internal_code,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%procedimentosTuss%'
            limit 1
        )                                                                   as tuss_code,

        -- status
        data ->> 'status'                                                   as status,

        -- observação (primeira nota)
        data -> 'note' -> 0 ->> 'text'                                     as note_text,
        (data -> 'note' -> 0 ->> 'time')::timestamptz                      as note_time,
        replace(
            data -> 'note' -> 0 -> 'authorReference' ->> 'reference',
            'Practitioner/', ''
        )                                                                   as note_author_id,

        -- extensões
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%verification-status%'
            limit 1
        )                                                                   as verification_status,
        replace(
            (
                select ext -> 'valueReference' ->> 'reference'
                from jsonb_array_elements(data -> 'extension') as ext
                where ext ->> 'url' like '%recorded-encounter%'
                limit 1
            ), 'Encounter/', ''
        )                                                                   as encounter_id,
        (
            select (ext ->> 'valueDateTime')::timestamptz
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%recorded-date%'
            limit 1
        )                                                                   as recorded_date,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
