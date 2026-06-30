{{
    config(
        materialized = 'table'
    )
}}

with fato as (
    select * from {{ ref('resposta_evento_adverso') }}
),

pivotado as (
    select
        id_resposta,

        -- contexto
        max(id_paciente)                                                    as id_paciente,
        max(id_atendimento)                                                 as id_atendimento,
        max(nome_autor)                                                     as nome_autor,
        max(data_resposta)                                                  as data_resposta,
        max(status)                                                         as status,

        -- perguntas pivotadas
        max(case when id_pergunta = '1734196460303' then resposta_escolha end)
                                                                             as ocorrencia_evento_adverso,
        max(case when id_pergunta = '1734196495482' then resposta_escolha end)
                                                                             as natureza_evento,
        max(case when id_pergunta = '1734196618575' then resposta_escolha end)
                                                                             as ciencia_notificacao,
        max(case when id_pergunta = '1734196637641' then resposta_texto end)
                                                                             as observacao_outros

    from fato
    group by id_resposta
)

select * from pivotado
