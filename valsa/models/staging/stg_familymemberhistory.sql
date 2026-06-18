with source as (
    select * from {{ source('prontlife', 'familymemberhistory') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as family_history_id,

        -- paciente
        replace(data -> 'patient' ->> 'reference', 'Patient/', '')         as patient_id,
        data -> 'patient' ->> 'display'                                     as patient_name,

        -- grau de parentesco
        data -> 'relationship' -> 'coding' -> 0 ->> 'code'                 as relationship_code,

        -- condição (primeira do array)
        data -> 'condition' -> 0 -> 'code' ->> 'text'                      as condition_name,
        (
            select item ->> 'code'
            from jsonb_array_elements(
                data -> 'condition' -> 0 -> 'code' -> 'coding'
            ) as item
            where item ->> 'system' like '%cid-10%'
            limit 1
        )                                                                   as cid10_code,
        (
            select item ->> 'display'
            from jsonb_array_elements(
                data -> 'condition' -> 0 -> 'code' -> 'coding'
            ) as item
            where item ->> 'system' like '%cid-10%'
            limit 1
        )                                                                   as cid10_display,

        -- observação da condição
        data -> 'condition' -> 0 -> 'note' -> 0 ->> 'text'                 as note_text,
        (data -> 'condition' -> 0 -> 'note' -> 0 ->> 'time')::timestamptz  as note_time,
        replace(
            data -> 'condition' -> 0 -> 'note' -> 0
                -> 'authorReference' ->> 'reference',
            'Practitioner/', ''
        )                                                                   as note_author_id,

        -- status
        data ->> 'status'                                                   as status,
        (data ->> 'date')::timestamptz                                      as date,

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
                where ext ->> 'url' like '%provider%'
                limit 1
            ), 'Practitioner/', ''
        )                                                                   as provider_id,
        (
            select ext -> 'valueReference' ->> 'display'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%provider%'
            limit 1
        )                                                                   as provider_name,
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
