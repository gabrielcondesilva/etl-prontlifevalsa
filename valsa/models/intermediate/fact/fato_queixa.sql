{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_observation_complaint') }}
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
        observation_id                                                      as id_queixa,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        performer_id                                                        as id_registrante,
        {{ capitalize_name("split_part(performer_name, ' - ', 1)") }}      as nome_registrante,

        -- queixa (código CIAP)
        complaint_code                                                      as codigo_ciap,
        complaint_name                                                      as nome_queixa,

        -- status traduzido
        case status
            when 'final'              then 'Final'
            when 'preliminary'        then 'Preliminar'
            when 'amended'            then 'Corrigido'
            when 'corrected'          then 'Corrigido'
            when 'cancelled'          then 'Cancelado'
            when 'entered-in-error'   then 'Erro de registro'
            else status
        end                                                                  as status,

        -- data
        (effective_datetime at time zone 'America/Sao_Paulo')::timestamp  as data_registro

    from mais_recente
)

select * from final
