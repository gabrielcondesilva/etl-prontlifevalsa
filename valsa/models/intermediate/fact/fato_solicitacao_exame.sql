{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_servicerequest') }}
    where category_code in ('363679005', '108252007')
),

numerado as (
    select
        *,
        row_number() over (
            partition by service_request_id, authored_on
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
        service_request_id                                                  as id_solicitacao,
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        requester_id                                                        as id_solicitante,

        case category_code
            when '363679005' then 'Exame de Imagem'
            when '108252007' then 'Exame de Laboratório'
        end                                                                  as categoria,

        request_name                                                        as nome_exame,
        imaging_type                                                        as tipo_imagem,

        case intent
            when 'order' then 'Ordem'
            when 'plan'  then 'Plano'
            else intent
        end                                                                  as tipo_pedido,
        case status
            when 'active'             then 'Ativa'
            when 'completed'          then 'Concluída'
            when 'cancelled'          then 'Cancelada'
            when 'revoked'            then 'Revogada'
            when 'draft'              then 'Rascunho'
            when 'entered-in-error'   then 'Erro de registro'
            when 'on-hold'            then 'Em espera'
            else status
        end                                                                  as status,

        reason                                                              as motivo,
        (authored_on at time zone 'America/Sao_Paulo')::timestamp         as data_solicitacao

    from mais_recente
)

select * from final
