{{
    config(
        materialized = 'table',
        tags = ['mart', 'qualidade']
    )
}}

with fato as (
    select * from {{ ref('fato_exame_lab') }}
),

tres_exames as (
    select *
    from fato
    where nome_exame in ('Creatinina (Cr)', 'Hemoglobina Glicada (A1C)', 'LDL')
),

flags as (
    select
        id_exame,
        id_paciente,
        nome_exame,
        valor_resultado,
        resultado_texto,
        unidade,
        status,
        data_exame,

        -- flag: resultado só existe em texto, sem número
        (valor_resultado is null and resultado_texto is not null) as resultado_apenas_texto,

        -- flag: valor numérico fora da faixa fisiologicamente plausível
        case
            when nome_exame = 'Creatinina (Cr)'
                then valor_resultado < 0.1 or valor_resultado > 15
            when nome_exame = 'Hemoglobina Glicada (A1C)'
                then valor_resultado < 3 or valor_resultado > 20
            when nome_exame = 'LDL'
                then valor_resultado < 0 or valor_resultado > 500
            else false
        end as valor_discrepante

    from tres_exames
)

select *
from flags
where resultado_apenas_texto = true
   or valor_discrepante = true
order by data_exame desc
