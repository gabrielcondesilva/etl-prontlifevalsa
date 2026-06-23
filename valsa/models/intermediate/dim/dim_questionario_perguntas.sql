{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dim']
    )
}}

with stg as (
    select * from {{ ref('stg_questionnaire_item') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by questionnaire_id, link_id
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
        -- chaves
        questionnaire_id                                                    as id_questionario,
        link_id                                                             as id_pergunta,

        -- agrupamento
        group_link_id                                                       as id_grupo,
        group_text                                                          as nome_grupo,

        -- pergunta
        question_text                                                       as texto_pergunta,

        -- tipo traduzido
        case question_type
            when 'choice'   then 'Escolha'
            when 'text'     then 'Texto'
            when 'quantity' then 'Quantidade'
            when 'group'    then 'Grupo'
            when 'display'  then 'Exibição'
            else question_type
        end                                                                  as tipo_pergunta,

        coalesce(required, false)                                          as obrigatoria,
        coalesce(repeats, false)                                           as permite_repeticao

    from mais_recente
)

select * from final
