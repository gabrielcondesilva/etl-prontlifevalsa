{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_procedure') }}
    where tuss_code is null
),

numerado as (
    select
        *,
        row_number() over (
            partition by procedure_id
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
        procedure_id                                                        as id_internacao,
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,

        recorder_id                                                         as id_registrante,
        case recorder_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else recorder_type
        end                                                                  as tipo_registrante,
        {{ capitalize_name("split_part(recorder_name, ' - ', 1)") }}       as nome_registrante,

        procedure_name                                                      as nome_evento,

        case status
            when 'completed'         then 'Concluído'
            when 'in-progress'       then 'Em andamento'
            when 'entered-in-error'  then 'Erro de registro'
            else status
        end                                                                  as status,

        case verification_status
            when 'confirmed'         then 'Confirmado'
            when 'unconfirmed'       then 'Não confirmado'
            when 'provisional'       then 'Provisório'
            else verification_status
        end                                                                  as status_verificacao,

        note_text                                                           as observacao,
        (recorded_date at time zone 'America/Sao_Paulo')::timestamp       as data_registro

    from mais_recente
)

select * from final
