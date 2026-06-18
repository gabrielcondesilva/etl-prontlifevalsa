with source as (
    select * from {{ source('prontlife', 'appointment') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as appointment_id,

        -- identificador externo
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:externalID'
            limit 1
        )                                                                   as external_id,

        -- participantes
        (
            select replace(part -> 'actor' ->> 'reference', 'Patient/', '')
            from jsonb_array_elements(data -> 'participant') as part
            where part -> 'type' -> 0 -> 'coding' -> 0 ->> 'code' = 'SBJ'
            limit 1
        )                                                                   as patient_id,
        (
            select replace(part -> 'actor' ->> 'reference', 'Location/', '')
            from jsonb_array_elements(data -> 'participant') as part
            where part -> 'type' -> 0 -> 'coding' -> 0 ->> 'code' = 'LOC'
            limit 1
        )                                                                   as location_id,
        (
            select replace(part -> 'actor' ->> 'reference', 'Practitioner/', '')
            from jsonb_array_elements(data -> 'participant') as part
            where part -> 'type' -> 0 -> 'coding' -> 0 ->> 'code' = 'PPRF'
            limit 1
        )                                                                   as practitioner_id,
        (
            select replace(part -> 'actor' ->> 'reference', 'Practitioner/', '')
            from jsonb_array_elements(data -> 'participant') as part
            where part -> 'type' -> 0 -> 'coding' -> 0 ->> 'code' = 'SPRF'
            limit 1
        )                                                                   as secondary_practitioner_id,

        -- status
        data ->> 'status'                                                   as status,

        -- datas
        (data ->> 'start')::timestamptz                                     as start_datetime,
        (data ->> 'end')::timestamptz                                       as end_datetime,
        (data ->> 'minutesDuration')::integer                               as minutes_duration,

        -- tipo de agendamento
        data -> 'appointmentType' -> 'coding' -> 0 ->> 'display'           as appointment_type,
        data -> 'appointmentType' -> 'coding' -> 0 ->> 'code'              as appointment_type_code,

        -- serviço (display vem dentro de coding no dado real)
        data -> 'serviceType' -> 0 -> 'coding' -> 0 ->> 'display'         as service_type,
        data -> 'serviceType' -> 0 -> 'coding' -> 0 ->> 'code'            as service_type_code,

        -- cancelamento
        data -> 'cancelationReason' -> 'coding' -> 0 ->> 'code'           as cancelation_reason_code,
        data -> 'cancelationReason' -> 'coding' -> 0 ->> 'display'        as cancelation_reason,

        -- observações e prioridade
        data ->> 'comment'                                                  as comment,
        (data ->> 'priority')::integer                                      as priority,

        -- extensões
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%newborn%'
            limit 1
        )                                                                   as is_newborn,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%fitted%'
            limit 1
        )                                                                   as is_fitted,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%appointment-by-arriva-order%'
            limit 1
        )                                                                   as by_arrival_order,
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%presence-type%'
            limit 1
        )                                                                   as presence_type,
        (
            select replace(ext -> 'valueReference' ->> 'reference', 'Coverage/', '')
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%coverage%'
            limit 1
        )                                                                   as coverage_id,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%send-mail%'
            limit 1
        )                                                                   as send_mail,
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%conference-token%'
            limit 1
        )                                                                   as conference_token,
        (
            select (ext ->> 'valueDateTime')::timestamptz
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%arrival-datetime%'
            limit 1
        )                                                                   as arrival_datetime,
        (
            select ext -> 'valueCoding' ->> 'code'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%atendimento-status%'
            limit 1
        )                                                                   as atendimento_status_code,
        (
            select ext -> 'valueCoding' ->> 'display'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%atendimento-status%'
            limit 1
        )                                                                   as atendimento_status,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
