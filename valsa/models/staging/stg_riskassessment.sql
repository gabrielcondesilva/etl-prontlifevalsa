with source as (
    select * from {{ source('prontlife', 'riskassessment') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as risk_assessment_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,
        replace(
            data -> 'basis' -> 0 ->> 'reference',
            'QuestionnaireResponse/', ''
        )                                                                   as questionnaire_response_id,

        -- performer (pode ser Practitioner, Patient ou Device)
        data -> 'performer' ->> 'reference'                                 as performer_reference,
        data -> 'performer' ->> 'display'                                   as performer_name,

        -- escore (identificação)
        data -> 'code' ->> 'text'                                           as score_name,
        data -> 'code' -> 'coding' -> 0 ->> 'code'                         as score_code,
        data -> 'code' -> 'coding' -> 0 ->> 'display'                      as score_display,

        -- método
        data -> 'method' -> 'coding' -> 0 ->> 'code'                       as method_code,
        data -> 'method' -> 'coding' -> 0 ->> 'display'                    as method_display,

        -- resultado qualitativo
        data -> 'prediction' -> 0 -> 'qualitativeRisk' -> 'coding' -> 0 ->> 'code'
                                                                            as prediction_code,
        data -> 'prediction' -> 0 -> 'qualitativeRisk' -> 'coding' -> 0 ->> 'display'
                                                                            as prediction_display,
        data -> 'prediction' -> 0 ->> 'rationale'                          as prediction_rationale,

        -- score numérico (extensão de topo)
        (
            select (ext ->> 'valueDecimal')::numeric
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%Extension/score%'
              and ext ->> 'url' not like '%score1%'
              and ext ->> 'url' not like '%score-color%'
            limit 1
        )                                                                   as score_value,

        -- extensões adicionais
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%summary%'
            limit 1
        )                                                                   as score_summary,
        (
            select (ext ->> 'valueDecimal')::numeric
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%dados-faltantes%'
            limit 1
        )                                                                   as missing_data,
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%fator-excludente%'
            limit 1
        )                                                                   as exclusion_factor,

        -- status e data
        data ->> 'status'                                                   as status,
        (data ->> 'occurrenceDateTime')::timestamptz                        as occurrence_datetime,

        -- identificador externo
        data -> 'identifier' -> 0 ->> 'value'                              as external_id,
        data -> 'identifier' -> 0 ->> 'system'                             as external_id_system,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
