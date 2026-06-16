with source as (
    select * from {{ source('prontlife', 'encounter') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as encounter_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'location' -> 0 -> 'location' ->> 'reference', 'Location/', '')
                                                                            as location_id,
        replace(data -> 'appointment' -> 0 ->> 'reference', 'Appointment/', '')
                                                                            as appointment_id,

        -- profissional principal (PPRF)
        (
            select replace(part -> 'individual' ->> 'reference', 'Practitioner/', '')
            from jsonb_array_elements(data -> 'participant') as part
            where part -> 'type' -> 0 -> 'coding' -> 0 ->> 'code' = 'PPRF'
            limit 1
        )                                                                   as practitioner_id,

        -- profissional secundário (SPRF)
        (
            select replace(part -> 'individual' ->> 'reference', 'Practitioner/', '')
            from jsonb_array_elements(data -> 'participant') as part
            where part -> 'type' -> 0 -> 'coding' -> 0 ->> 'code' = 'SPRF'
            limit 1
        )                                                                   as secondary_practitioner_id,

        -- status
        data ->> 'status'                                                   as status,

        -- classificação
        data -> 'class' ->> 'code'                                         as class_code,
        data -> 'class' ->> 'display'                                       as class_display,

        -- tipo de atendimento
        data -> 'type' -> 0 -> 'coding' -> 0 ->> 'code'                   as type_code,
        data -> 'type' -> 0 -> 'coding' -> 0 ->> 'display'                as type_display,

        -- período
        (data -> 'period' ->> 'start')::timestamptz                        as period_start,
        (data -> 'period' ->> 'end')::timestamptz                          as period_end,

        -- extensões
        (
            select replace(ext -> 'valueReference' ->> 'reference', 'Coverage/', '')
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%coverage%'
            limit 1
        )                                                                   as coverage_id,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%encounter-finalizado-admistrativamente%'
            limit 1
        )                                                                   as finished_administratively,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%encounter-iniciado-admistrativamente%'
            limit 1
        )                                                                   as started_administratively,
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%presence-type%'
            limit 1
        )                                                                   as presence_type,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
