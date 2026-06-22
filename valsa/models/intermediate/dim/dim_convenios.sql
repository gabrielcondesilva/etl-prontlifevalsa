{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dim']
    )
}}

with stg as (
    select * from {{ ref('stg_healthinsurance') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by healthinsurance_id
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
        healthinsurance_id as id_convenio,

        -- convênio
        name              as nome_convenio,
        corporate_name    as razao_social,

        -- status
        case status
            when 'active'   then 'Ativo'
            when 'inactive' then 'Inativo'
            else status
        end as status

    from mais_recente
)

select * from final
