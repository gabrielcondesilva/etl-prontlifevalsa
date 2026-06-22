{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dim']
    )
}}

with stg as (
    select * from {{ ref('stg_healthinsuranceplan') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by healthinsuranceplan_id
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
        healthinsuranceplan_id as id_plano_convenio,

        -- referências
        healthinsurance_id     as id_convenio,

        -- plano
        name                  as nome_plano,

        -- status
        case status
            when 'active'   then 'Ativo'
            when 'inactive' then 'Inativo'
            else status
        end                   as status

    from mais_recente
)

select * from final
