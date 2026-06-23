{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dim']
    )
}}

with stg as (
    select * from {{ ref('stg_questionnaire') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by questionnaire_id
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
        questionnaire_id                                                    as id_questionario,

        -- dados do questionário
        title                                                                as nome_questionario,

        -- status traduzido
        case status
            when 'active' then 'Ativo'
            when 'draft'  then 'Rascunho'
            else status
        end                                                                  as status,

        description                                                         as descricao

    from mais_recente
)

select * from final
