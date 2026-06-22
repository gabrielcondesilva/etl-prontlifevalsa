with source as (
    select * from {{ source('prontlife', 'servicerequest') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as service_request_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,
        split_part(data -> 'requester' ->> 'reference', '/', 2)            as requester_id,
        split_part(data -> 'requester' ->> 'reference', '/', 1)            as requester_type,
        data -> 'requester' ->> 'display'                                   as requester_name,

        -- categoria (discriminador do tipo de solicitação)
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'               as category_code,
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'display'             as category_display,

        -- código do exame/procedimento
        data -> 'code' ->> 'text'                                           as request_name,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%procedimentos%'
              and item ->> 'system' not like '%TUSS%'
            limit 1
        )                                                                   as request_code,
        (
            select item ->> 'display'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%procedimentos%'
              and item ->> 'system' not like '%TUSS%'
            limit 1
        )                                                                   as request_display,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%TUSS%'
            limit 1
        )                                                                   as tuss_code,

        -- tipo de imagem (extensão — só para exames de imagem)
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%exames-terminologia-tipo%'
            limit 1
        )                                                                   as imaging_type,

        -- especialidade do encaminhamento (performerType)
        (
            select item ->> 'display'
            from jsonb_array_elements(data -> 'performerType' -> 'coding') as item
            where item ->> 'system' like '%specialty%'
            limit 1
        )                                                                   as specialty_name,
        (
            select item ->> 'display'
            from jsonb_array_elements(data -> 'performerType' -> 'coding') as item
            where item ->> 'system' like '%mtecbo%'
            limit 1
        )                                                                   as specialty_cbo_name,

        -- intent, status e justificativa
        data ->> 'intent'                                                   as intent,
        data ->> 'status'                                                   as status,
        data -> 'reasonCode' -> 0 ->> 'text'                               as reason,

        -- instrução ao paciente (orientação de saúde)
        data ->> 'patientInstruction'                                       as patient_instruction,

        -- periodicidade (pontual, contínuo, etc.)
        data -> 'occurrenceTiming' -> 'code' ->> 'text'                    as occurrence_timing,

        -- data da solicitação
        (data ->> 'authoredOn')::timestamptz                               as authored_on,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
