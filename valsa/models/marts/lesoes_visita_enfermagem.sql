{{
    config(
        materialized = 'table',
        tags = ['mart', 'lesoes']
    )
}}

with base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(data_resposta) as data_resposta,
        max(status) as status,
        max(case when texto_pergunta = 'Apresenta alguma lesão ou ferida corpo' then coalesce(resposta_escolha, resposta_codigo, resposta_texto) end) as apresenta_lesao,
        max(case when texto_pergunta = 'Qual tipo de lesão ou ferida:' then coalesce(resposta_escolha, resposta_codigo, resposta_texto) end) as tipo_lesao,
        max(case when texto_pergunta = 'Descreva a lesão:' then coalesce(resposta_texto, resposta_escolha, resposta_codigo) end) as descricao_lesao,
        max(case when texto_pergunta = 'Descreva a região da lesão:' then coalesce(resposta_texto, resposta_escolha, resposta_codigo) end) as regiao_lesao,
        max(case when texto_pergunta = 'Grau da lesão:' then coalesce(resposta_escolha, resposta_codigo, resposta_texto) end) as grau_lesao,
        max(case when texto_pergunta = 'Extensão da lesão:' then coalesce(resposta_texto, resposta_escolha, resposta_codigo) end) as extensao_lesao,
        max(case when texto_pergunta = 'Leito da lesão:' then coalesce(resposta_escolha, resposta_codigo, resposta_texto) end) as leito_lesao,
        max(case when texto_pergunta = 'Evolução da lesão:' then coalesce(resposta_escolha, resposta_codigo, resposta_texto) end) as evolucao_lesao,
        max(case when texto_pergunta = 'Já trata a lesão:' then coalesce(resposta_escolha, resposta_codigo, resposta_texto) end) as ja_trata_lesao
    from {{ ref('resposta_valsa_visita_enfermagem_rotina') }}
    where status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
)
select *
from base
where apresenta_lesao is not null
