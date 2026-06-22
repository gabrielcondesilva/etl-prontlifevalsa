{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_observation_habits') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by observation_id
            order by
                delivery_date desc,
                issued desc
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
        observation_id as id_habito,

        -- referências
        patient_id as id_paciente,

        case encounter_id
            when 'undefined' then null
            else encounter_id
        end as id_atendimento,

        case
            when performer_id like 'Patient/%'
                then split_part(performer_id, '/', 2)
            else performer_id
        end as id_registrante,

        case
            when performer_id like 'Patient/%' then 'Paciente'
            when performer_id is not null then 'Profissional'
            else null
        end as tipo_registrante,

        {{ capitalize_name("performer_name") }} as nome_registrante,

        -- hábito
        coalesce(
            nullif(habit_value_display, ''),
            nullif(habit_value, '')
        ) as habito,

        -- métricas
        cigarettes_per_day as cigarros_por_dia,
        smoking_years as anos_tabagismo,
        packs_per_year as macos_por_ano,
        alcohol_doses_per_week as doses_alcool_por_semana,

        -- observação
        note_text as observacao,

        -- status
        case status
            when 'final'       then 'Final'
            when 'amended'     then 'Alterado'
            when 'preliminary' then 'Preliminar'
            else status
        end as status,

        -- data
        (issued at time zone 'America/Sao_Paulo')::timestamp as data_emissao

    from mais_recente
)

select * from final
