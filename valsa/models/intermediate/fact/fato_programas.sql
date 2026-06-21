{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_customepisodeofcare') }}
),

-- normaliza a categoria antes de qualquer dedup (resolve "melhores cuidados" vs "Melhores Cuidados")
normalizado as (
    select
        *,
        {{ capitalize_name('category_display') }} as category_display_norm
    from stg
),

-- camada 1: mais novo ganha por episode_of_care_id (resolve múltiplas versões do mesmo episódio)
numerado_episodio as (
    select
        *,
        row_number() over (
            partition by episode_of_care_id
            order by delivery_date desc
        ) as rn_episodio
    from normalizado
),

mais_recente_episodio as (
    select *
    from numerado_episodio
    where rn_episodio = 1
),

-- camada 2: dedup por chave de negócio (resolve episode_of_care_id duplicados por bug da fonte)
numerado_negocio as (
    select
        *,
        row_number() over (
            partition by patient_id, category_display_norm, period_start
            order by delivery_date desc
        ) as rn_negocio
    from mais_recente_episodio
),

final as (
    select
        -- chave
        episode_of_care_id                                                  as id_episodio,

        -- paciente
        patient_id                                                          as id_paciente,

        -- programa
        category_display_norm                                               as nome_programa,

        -- gestor
        care_manager_id                                                     as id_gestor,
        care_manager_name                                                   as nome_gestor,
        care_manager_role                                                   as papel_gestor,

        -- status traduzido
        case status
            when 'active'   then 'Ativo'
            when 'inactive' then 'Inativo'
            else status
        end                                                                  as status_paciente,

        -- período (sem timezone, horário de Brasília)
        (period_start at time zone 'America/Sao_Paulo')::timestamp         as data_admissao,
        (period_end at time zone 'America/Sao_Paulo')::timestamp           as data_fim_prevista,
        (inactivation_datetime at time zone 'America/Sao_Paulo')::timestamp
                                                                            as data_inativacao,

        -- observação
        note                                                                as observacao

    from numerado_negocio
    where rn_negocio = 1
)

select * from final
