{{
    config(
        materialized = 'table'
    )
}}

select
    t1.id_encaminhamento,
    t1.id_paciente,
    t1.id_atendimento,
    t1.especialidade                                as especialidade_encaminhada,
    t1.id_solicitante,
    t2.nome_completo                                as nome_solicitante,
    t2.especialidade                                as especialidade_solicitante,
    t1.status                                       as status_encaminhamento,
    t1.motivo                                       as motivo_encaminhamento,
    t1.data_solicitacao
from prontlife_intermediate.fato_encaminhamento t1
left join prontlife_intermediate.dim_profissionais t2
    on t1.id_solicitante = t2.id_profissional
