{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_observation_hpi') }}
),

final as (
    select
        -- chave
        observation_id as id_observacao_hpi,

        -- referências
        patient_id as id_paciente,

        case encounter_id
            when 'undefined' then null
            else encounter_id
        end as id_atendimento,

        performer_id as id_registrante,

        {{ capitalize_name("performer_name") }} as nome_registrante,

        -- observação clínica
        hpi_text as texto_hpi,

        -- status
        case status
            when 'final' then 'Final'
            else status
        end as status,

        -- data
        (effective_datetime at time zone 'America/Sao_Paulo')::timestamp as data_observacao

    from stg
)

select * from final
