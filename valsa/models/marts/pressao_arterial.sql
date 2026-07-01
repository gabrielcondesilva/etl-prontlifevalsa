{{
    config(
        materialized = 'table',
        tags = ['mart', 'exames']
    )
}}
with aps_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Pressão Arterial Sistólica' and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Pressão Arterial Diastólica' and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_aps_doc_acolhimento_enfermagem') }}
    where texto_pergunta in (
        'Pressão Arterial Sistólica',
        'Pressão Arterial Diastólica'
    )
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
aps_doc_acolhimento_enfermagem as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'APS - Acolhimento Enfermagem' as origem
    from aps_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
avaliacao_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Pressão arterial sistólica (mmHg)' and resposta_inteiro > 0 then resposta_inteiro end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Pressão arterial diastólica (mmHg)' and resposta_inteiro > 0 then resposta_inteiro end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_avaliacao_breve_risco_saude') }}
    where texto_pergunta in (
        'Pressão arterial sistólica (mmHg)',
        'Pressão arterial diastólica (mmHg)'
    )
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
avaliacao_breve_risco_saude as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'Avaliação Breve de Risco à Saúde' as origem
    from avaliacao_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
exame_medico_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Pressão arterial sistólica' and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Pressão arterial diastólica' and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_exame_medico_visita_domiciliar') }}
    where texto_pergunta in (
        'Pressão arterial sistólica',
        'Pressão arterial diastólica'
    )
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
exame_medico_visita_domiciliar as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'Exame Médico - Visita Domiciliar' as origem
    from exame_medico_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
valsa_1_enfermagem_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Pressão arterial:' and sequencia_resposta = 1 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Pressão arterial:' and sequencia_resposta = 2 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_valsa_1_visita_enfermagem') }}
    where texto_pergunta = 'Pressão arterial:'
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
valsa_1_visita_enfermagem as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'VALSA - 1ª Visita Enfermagem' as origem
    from valsa_1_enfermagem_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
valsa_consulta_medica_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when trim(texto_pergunta) = 'Pressão Arterial' and sequencia_resposta = 1 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when trim(texto_pergunta) = 'Pressão Arterial' and sequencia_resposta = 2 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_valsa_consulta_medica_lc') }}
    where trim(texto_pergunta) = 'Pressão Arterial'
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
valsa_consulta_medica_lc as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'VALSA - Consulta Médica LC' as origem
    from valsa_consulta_medica_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
valsa_intercorrencia_base as (
    select
            id_resposta,
            id_paciente,
            id_atendimento,
            max(case when texto_pergunta = 'Pressão arterial (mmHg): ' and sequencia_resposta = 1 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
            max(case when texto_pergunta = 'Pressão arterial (mmHg): ' and sequencia_resposta = 2 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
            max(data_resposta) as data_afericao
        from {{ ref('resposta_valsa_intercorrencia') }}
        where texto_pergunta = 'Pressão arterial (mmHg): '
        and status = 'Concluído'
        group by
            id_resposta,
            id_paciente,
            id_atendimento
    ),
valsa_intercorrencia as (
    select
            id_resposta,
            id_paciente,
            id_atendimento,
            greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
            least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
            data_afericao,
            'VALSA - Intercorrência' as origem
        from valsa_intercorrencia_base
        where
            pressao_sistolica_original is not null
            and pressao_diastolica_original is not null
    ),
valsa_monitoramento_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Qual foi o último valor da aferição da Pressão Arterial:' and sequencia_resposta = 1 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Qual foi o último valor da aferição da Pressão Arterial:' and sequencia_resposta = 2 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_valsa_monitoramento_saude') }}
    where texto_pergunta = 'Qual foi o último valor da aferição da Pressão Arterial:'
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
valsa_monitoramento_saude as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'VALSA - Monitoramento de Saúde' as origem
    from valsa_monitoramento_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
valsa_enfermagem_rotina_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Pressão arterial:' and sequencia_resposta = 1 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Pressão arterial:' and sequencia_resposta = 2 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_valsa_visita_enfermagem_rotina') }}
    where texto_pergunta = 'Pressão arterial:'
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
valsa_visita_enfermagem_rotina as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'VALSA - Visita Enfermagem Rotina' as origem
    from valsa_enfermagem_rotina_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
valsa_visita_medica_base as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        max(case when texto_pergunta = 'Pressão arterial (mmHg):' and sequencia_resposta = 1 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_sistolica_original,
        max(case when texto_pergunta = 'Pressão arterial (mmHg):' and sequencia_resposta = 2 and resposta_quantidade_valor > 0 then resposta_quantidade_valor end) as pressao_diastolica_original,
        max(data_resposta) as data_afericao
    from {{ ref('resposta_valsa_visita_medica') }}
    where texto_pergunta = 'Pressão arterial (mmHg):'
    and status = 'Concluído'
    group by
        id_resposta,
        id_paciente,
        id_atendimento
),
valsa_visita_medica as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'VALSA - Visita Médica' as origem
    from valsa_visita_medica_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
),
exame_fisico_base as (
    select
        id_medicao as id_resposta,
        id_paciente,
        id_atendimento,
        pressao_sistolica as pressao_sistolica_original,
        pressao_diastolica as pressao_diastolica_original,
        data_medicao as data_afericao
    from {{ ref('fato_exame_fisico') }}
    where nome_exame = 'Pressão Arterial (sentado)'
),
exame_fisico as (
    select
        id_resposta,
        id_paciente,
        id_atendimento,
        greatest(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_sistolica,
        least(round(pressao_sistolica_original)::int, round(pressao_diastolica_original)::int) as pressao_diastolica,
        data_afericao,
        'Exame Físico' as origem
    from exame_fisico_base
    where
        pressao_sistolica_original is not null
        and pressao_diastolica_original is not null
        and pressao_sistolica_original > 0
        and pressao_diastolica_original > 0
)
select * from aps_doc_acolhimento_enfermagem
union all
select * from avaliacao_breve_risco_saude
union all
select * from exame_medico_visita_domiciliar
union all
select * from valsa_1_visita_enfermagem
union all
select * from valsa_consulta_medica_lc
union all
select * from valsa_intercorrencia
union all
select * from valsa_monitoramento_saude
union all
select * from valsa_visita_enfermagem_rotina
union all
select * from valsa_visita_medica
union all
select * from exame_fisico
