with source as (
    select * from {{ source('prontlife', 'immunization') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as immunization_id,

        -- paciente
        replace(data -> 'patient' ->> 'reference', 'Patient/', '')         as patient_id,

        -- profissional (pode ser Practitioner ou Patient)
        split_part(data -> 'performer' -> 'actor' ->> 'reference', '/', 2) as performer_id,
        split_part(data -> 'performer' -> 'actor' ->> 'reference', '/', 1) as performer_type,

        -- vacina
        coalesce(
            data -> 'vaccineCode' ->> 'text',
            data -> 'vaccineCode' -> 'coding' -> 0 ->> 'display'
        )                                                                   as vaccine_name,
        data -> 'vaccineCode' -> 'coding' -> 0 ->> 'code'                  as vaccine_code,

        -- status e observação
        data ->> 'status'                                                   as status,
        data ->> 'note'                                                     as note,

        -- datas
        (data ->> 'recorded')::timestamptz                                  as recorded,
        (data ->> 'occurrenceDateTime')::timestamptz                       as occurrence_datetime,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
