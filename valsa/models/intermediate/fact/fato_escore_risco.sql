{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_riskassessment') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by risk_assessment_id
            order by
                delivery_date desc,
                occurrence_datetime desc
        ) as rn
    from stg
),

mais_recente as (
    select *
    from numerado
    where rn = 1
),

final as (
    select
        -- chave
        risk_assessment_id                                                as id_escore_risco,

        -- referências
        patient_id                                                        as id_paciente,

        case encounter_id
            when 'undefined' then null
            else encounter_id
        end                                                               as id_atendimento,

        questionnaire_response_id                                         as id_questionario_resposta,

        split_part(performer_reference, '/', 2)                           as id_registrante,

        case split_part(performer_reference, '/', 1)
            when 'Practitioner' then 'Profissional'
            when 'Device'       then 'Dispositivo'
            else split_part(performer_reference, '/', 1)
        end                                                               as tipo_registrante,

        {{ capitalize_name("performer_name") }}                           as nome_registrante,

        -- escore
        method_display                                                    as nome_escore,

        -- resultado
        prediction_code                                                   as codigo_predicao,
        prediction_display                                                as predicao,
        prediction_rationale                                              as justificativa_predicao,
        score_value                                                       as valor_escore,

        -- status
        case status
            when 'final'       then 'Final'
            when 'preliminary' then 'Preliminar'
            else status
        end                                                               as status,

        -- data
        (occurrence_datetime at time zone 'America/Sao_Paulo')::timestamp as data_ocorrencia

    from mais_recente
)

select * from final
