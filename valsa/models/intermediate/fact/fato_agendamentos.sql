{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_appointment') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by appointment_id
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
        appointment_id                                                      as id_agendamento,

        -- dimensões relacionadas
        patient_id                                                          as id_paciente,
        location_id                                                         as id_unidade,
        practitioner_id                                                     as id_profissional,
        secondary_practitioner_id                                           as id_profissional_secundario,
        coverage_id                                                         as id_convenio,

        -- status traduzido
        case status
            when 'proposed'          then 'Proposto'
            when 'pending'           then 'Pendente'
            when 'booked'            then 'Agendado'
            when 'arrived'           then 'Chegou'
            when 'fulfilled'         then 'Realizado'
            when 'cancelled'         then 'Cancelado'
            when 'noshow'            then 'Não compareceu'
            when 'entered-in-error'  then 'Erro de registro'
            when 'checked-in'        then 'Check-in feito'
            when 'waitlist'          then 'Lista de espera'
            else status
        end                                                                  as status,

        -- período (sem timezone, horário de Brasília)
        (start_datetime at time zone 'America/Sao_Paulo')::timestamp       as data_inicio,
        (end_datetime at time zone 'America/Sao_Paulo')::timestamp         as data_fim,
        minutes_duration                                                    as duracao_minutos,

        -- tipo de agendamento
        appointment_type                                                    as tipo_agendamento,
        service_type                                                        as tipo_servico,

        -- cancelamento
        cancelation_reason                                                  as motivo_cancelamento,

        -- detalhes
        comment                                                             as observacao,
        priority                                                            as prioridade,
        presence_type                                                       as tipo_presenca,
        atendimento_status                                                  as status_atendimento

    from mais_recente
)

select * from final
