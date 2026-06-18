with source as (
    select * from {{ source('prontlife', 'observation_history_of_present_illness') }}
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

        -- texto da HDA (conteúdo principal — sensível LGPD)
        data ->> 'valueString'                                              as hpi_text,

        -- código (fixo — identifica como HDA)
        data -> 'code' -> 'coding' -> 0 ->> 'code'                         as code,
        data -> 'code' -> 'coding' -> 0 ->> 'system'                       as code_system,

        -- status e data
        data ->> 'status'                                                   as status,
        (data ->> 'effectiveDateTime')::timestamptz                         as effective_datetime,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
