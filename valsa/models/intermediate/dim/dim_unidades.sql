{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dimension']
    )
}}

with stg as (
    select * from {{ ref('stg_location') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by location_id
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
        location_id                                                         as id_unidade,

        -- identificação
        -- identificação
        {{ unescape_html('name') }}                                         as nome_unidade,
        case status
            when 'active'    then 'Ativo'
            when 'suspended' then 'Suspenso'
            when 'inactive'  then 'Inativo'
            else status
        end                                                                  as status,

        -- contato
        phone                                                                as telefone,

        -- localização
        {{ capitalize_name('address_text')}}                                                        as endereco,
        {{ capitalize_name('district') }}                                   as bairro,
        {{ capitalize_name('city') }}                                       as cidade,
        upper(state)                                                        as estado

    from mais_recente
)

select * from final
