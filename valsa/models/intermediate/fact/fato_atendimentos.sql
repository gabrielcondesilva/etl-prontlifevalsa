{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_encounter') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by encounter_id
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
        encounter_id                                                        as id_atendimento,

        -- dimensões relacionadas
        patient_id                                                          as id_paciente,
        location_id                                                         as id_unidade,
        practitioner_id                                                     as id_profissional,
        secondary_practitioner_id                                           as id_profissional_secundario,
        appointment_id                                                      as id_agendamento,
        coverage_id                                                         as id_convenio,

        -- status traduzido
        case status
            when 'planned'           then 'Planejado'
            when 'arrived'           then 'Chegou'
            when 'triaged'           then 'Triado'
            when 'in-progress'       then 'Em andamento'
            when 'onleave'           then 'Em licença'
            when 'finished'          then 'Finalizado'
            when 'cancelled'         then 'Cancelado'
            when 'entered-in-error'  then 'Erro de registro'
            when 'unknown'           then 'Desconhecido'
            else status
        end                                                                  as status,

        -- classificação traduzida
        case class_code
            when 'AMB'    then 'Ambulatorial'
            when 'EMER'   then 'Emergência'
            when 'IMP'    then 'Internação'
            when 'VR'     then 'Virtual'
            when 'EV_ENF' then 'Enfermagem'
            else class_display
        end                                                                  as classificacao,

        type_display                                                        as tipo_atendimento,

        -- período (sem timezone, horário de Brasília)
        (period_start at time zone 'America/Sao_Paulo')::timestamp          as data_inicio,
        (period_end at time zone 'America/Sao_Paulo')::timestamp            as data_fim,
        extract(
            epoch from (period_end - period_start)
        )::integer / 60                                                     as duracao_minutos

    from mais_recente
)

select * from final
