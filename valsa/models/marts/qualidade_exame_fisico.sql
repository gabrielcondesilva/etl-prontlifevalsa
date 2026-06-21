{{
    config(
        materialized = 'table',
        tags = ['mart', 'qualidade']
    )
}}

with fato as (
    select * from {{ ref('fato_exame_fisico') }}
),

pressao as (
    select *
    from fato
    where nome_exame in ('Pressão Arterial (sentado)', 'Pressão Arterial (deitado)')
),

flags as (
    select
        id_medicao,
        id_paciente,
        id_atendimento,
        id_registrante,
        nome_registrante,
        nome_exame,
        pressao_sistolica,
        pressao_diastolica,
        pressao_media,
        data_medicao,

        -- flag: pressão arterial implausível
        (
            pressao_sistolica < pressao_diastolica
            or pressao_sistolica < 30
            or pressao_diastolica > 200
        ) as pressao_suspeita

    from pressao
    where pressao_sistolica is not null
      and pressao_diastolica is not null
)

select *
from flags
where pressao_suspeita = true
order by data_medicao desc
