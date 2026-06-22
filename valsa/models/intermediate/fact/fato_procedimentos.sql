{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_procedure') }}
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
        -- chave
        procedure_id                                                        as id_procedimento,

        -- paciente
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,

        -- registrante (pode ser profissional ou paciente)
        recorder_id                                                         as id_registrante,
        case recorder_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else recorder_type
        end                                                                  as tipo_registrante,
        {{ capitalize_name("split_part(recorder_name, ' - ', 1)") }}       as nome_registrante,

        -- procedimento
        procedure_name                                                      as nome_procedimento,

        -- status traduzido
        case status
            when 'completed'         then 'Concluído'
            when 'in-progress'       then 'Em andamento'
            when 'not-done'          then 'Não realizado'
            when 'stopped'           then 'Interrompido'
            when 'on-hold'           then 'Em espera'
            when 'entered-in-error'  then 'Erro de registro'
            when 'unknown'           then 'Desconhecido'
            else status
        end                                                                  as status,

        -- status de verificação traduzido
        case verification_status
            when 'confirmed'         then 'Confirmado'
            when 'unconfirmed'       then 'Não confirmado'
            when 'provisional'       then 'Provisório'
            when 'entered-in-error'  then 'Erro'
            else verification_status
        end                                                                  as status_verificacao,

        -- observação
        note_text                                                           as observacao,

        -- data
        (recorded_date at time zone 'America/Sao_Paulo')::timestamp       as data_registro

    from mais_recente
)

select * from final
