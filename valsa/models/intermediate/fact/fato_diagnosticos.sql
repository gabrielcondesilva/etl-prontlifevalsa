{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_condition_diagnosis') }}
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

extraido as (
    select
        *,
        (regexp_match(cid10_display, 'CID10\s*-\s*"*([A-Z]\d{2}(?:\.\d+)?)'))[1] as cid10_extraido_do_display
    from mais_recente
),

final as (
    select
        condition_id                                                        as id_diagnostico,

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

        coalesce(cid10_extraido_do_display, cid10_internal_code)            as codigo_cid10,

        trim(
            regexp_replace(cid10_display, '\s*\(CID10\s*-\s*"*[A-Z]\d{2}(?:\.\d+)?"*\)\s*$', '')
        )                                                                    as descricao_cid10,

        case clinical_status
            when 'active'      then 'Ativa'
            when 'inactive'    then 'Inativa'
            when 'recurrence'  then 'Reincidência (Ativa)'
            when 'relapse'     then 'Recaída (Ativa)'
            when 'remission'   then 'Remissão (Inativa)'
            when 'resolved'    then 'Curada (Inativa)'
            else clinical_status
        end                                                                  as status_clinico,

        case verification_status
            when 'confirmed'         then 'Confirmado'
            when 'unconfirmed'       then 'Não confirmado'
            when 'provisional'       then 'Provisório'
            when 'differential'      then 'Diferencial'
            when 'refuted'           then 'Refutado'
            when 'entered-in-error'  then 'Erro'
            else verification_status
        end                                                                  as status_verificacao,

        note                                                                as observacao,

        (recorded_date at time zone 'America/Sao_Paulo')::timestamp        as data_registro

    from extraido
)

select * from final
