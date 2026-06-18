with source as (
    select * from {{ source('prontlife', 'medicationrequest') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as medication_request_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,
        replace(data -> 'recorder' ->> 'reference', 'Practitioner/', '')   as recorder_id,
        data -> 'recorder' ->> 'display'                                    as recorder_name,
        replace(data -> 'requester' ->> 'reference', 'Practitioner/', '')  as requester_id,
        data -> 'requester' ->> 'display'                                   as requester_name,

        -- medicamento
        replace(
            data -> 'medicationReference' ->> 'reference', 'Medication/', ''
        )                                                                   as medication_id,
        data -> 'medicationReference' ->> 'display'                         as medication_name,

        -- categoria e tipo
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'               as category_code,
        data -> 'courseOfTherapyType' -> 'coding' -> 0 ->> 'code'          as therapy_type,

        -- tipo de receituário
        (
            select ext -> 'valueCoding' ->> 'display'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%medicationrequest-controle%'
            limit 1
        )                                                                   as prescription_type,

        -- posologia (primeira instrução)
        data -> 'dosageInstruction' -> 0 ->> 'text'                        as dosage_text,
        data -> 'dosageInstruction' -> 0 -> 'route' -> 'coding' -> 0 ->> 'display'
                                                                            as route,
        (
            data -> 'dosageInstruction' -> 0 -> 'doseAndRate' -> 0
                -> 'doseQuantity' ->> 'value'
        )::numeric                                                          as dose_value,
        data -> 'dosageInstruction' -> 0 -> 'doseAndRate' -> 0
            -> 'doseQuantity' ->> 'unit'                                    as dose_unit,
        (
            data -> 'dosageInstruction' -> 0 -> 'timing' -> 'repeat' ->> 'frequency'
        )::integer                                                          as frequency,
        data -> 'dosageInstruction' -> 0 -> 'timing' -> 'repeat' ->> 'periodUnit'
                                                                            as frequency_unit,
        data -> 'dosageInstruction' -> 0 -> 'timing' -> 'repeat' -> 'when' -> 0
                                                                            as schedule,
        (
            data -> 'dosageInstruction' -> 0 -> 'timing' -> 'repeat'
                -> 'boundsDuration' ->> 'value'
        )::integer                                                          as duration_value,
        data -> 'dosageInstruction' -> 0 -> 'timing' -> 'repeat'
            -> 'boundsDuration' ->> 'unit'                                  as duration_unit,
        (
            data -> 'dosageInstruction' -> 0 ->> 'asNeededBoolean'
        )::boolean                                                          as as_needed,

        -- intent, status e observação
        data ->> 'intent'                                                   as intent,
        data ->> 'status'                                                   as status,
        data -> 'note' -> 0 ->> 'text'                                     as note,

        -- data da prescrição
        (data ->> 'authoredOn')::timestamptz                               as authored_on,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
