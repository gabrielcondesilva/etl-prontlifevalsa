{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_servicerequest') }}
    where category_code = '405103001'
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
        service_request_id                                                  as id_orientacao,
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        requester_id                                                        as id_solicitante,

        request_name                                                        as tipo_orientacao,
        patient_instruction                                                 as instrucao,

        case occurrence_timing
            when 'Pontual'   then 'Pontual'
            when 'Continuo'  then 'Contínuo'
            else occurrence_timing
        end                                                                  as periodicidade,

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

        (authored_on at time zone 'America/Sao_Paulo')::timestamp         as data_orientacao

    from mais_recente
)

select * from final
