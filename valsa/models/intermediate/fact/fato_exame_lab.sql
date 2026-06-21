{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_observation_lab') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by observation_id
            order by delivery_date desc
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
        observation_id                                                      as id_exame,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        performer_id                                                        as id_registrante,
        case performer_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else performer_type
        end                                                                  as tipo_registrante,
        {{ capitalize_name("split_part(performer_name, ' - ', 1)") }}      as nome_registrante,

        -- exame (nome padronizado)
        case
            when coalesce(exam_display, exam_name) in (
                'Hemoglobina glicada (Fração A1c) - pesquisa e/ou dosagem',
                'Hemoglobina Glicada (A1C)'
            ) then 'Hemoglobina Glicada (A1C)'
            when coalesce(exam_display, exam_name) in (
                'Vit B12',
                'Vitamina B12'
            ) then 'Vitamina B12'
            when coalesce(exam_display, exam_name) = 'TSH (Hormônio Tireoestimulante)'
                then 'TSH'
            when coalesce(exam_display, exam_name) in (
                'Insulina total e livre',
                'Insulina - pesquisa e/ou dosagem'
            ) then 'Insulina'
            else coalesce(exam_display, exam_name)
        end                                                                  as nome_exame,

        -- resultado
        result_value                                                        as valor_resultado,
        result_unit                                                         as unidade,
        result_text                                                         as resultado_texto,

        -- status traduzido e data
        case status
            when 'registered'        then 'Registrado'
            when 'preliminary'       then 'Preliminar'
            when 'final'             then 'Final'
            when 'amended'           then 'Corrigido'
            when 'corrected'         then 'Corrigido'
            when 'cancelled'         then 'Cancelado'
            when 'entered-in-error'  then 'Erro de registro'
            when 'unknown'           then 'Desconhecido'
            else status
        end                                                                  as status,
        (effective_datetime at time zone 'America/Sao_Paulo')::timestamp  as data_exame

    from mais_recente
)

select * from final
