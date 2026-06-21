{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_condition') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by condition_id
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
        condition_id                                                        as id_diagnostico,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,

        -- registrante (pode ser profissional ou o próprio paciente)
        recorder_id                                                         as id_registrante,
        case recorder_reference_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else recorder_reference_type
        end                                                                  as tipo_registrante,
        {{ capitalize_name('recorder_name') }}                              as nome_registrante,

        -- diagnóstico
        diagnosis_name                                                      as nome_diagnostico,
        cid10_code                                                          as codigo_cid10,
        cid10_display                                                       as descricao_cid10,

        -- categoria traduzida
        case category_code
            when 'problem-list-item'    then 'Registro de Doença'
            when 'encounter-diagnosis'  then 'Diagnóstico em Atendimento'
            else category_display
        end                                                                  as categoria,

        -- gravidade traduzida
        case severity_code
            when '24484000'   then 'Severa'
            when '6736007'    then 'Moderada'
            when '255604002'  then 'Leve'
            else severity_display
        end                                                                  as gravidade,

        -- status clínico traduzido
        case clinical_status
            when 'active'      then 'Ativa'
            when 'inactive'    then 'Inativa'
            when 'recurrence'  then 'Reincidência (Ativa)'
            when 'relapse'     then 'Recaída (Ativa)'
            when 'remission'   then 'Remissão (Inativa)'
            when 'resolved'    then 'Curada (Inativa)'
            else clinical_status
        end                                                                  as status_clinico,

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
        (recorded_date at time zone 'America/Sao_Paulo')::timestamp        as data_registro

    from mais_recente
)

select * from final
