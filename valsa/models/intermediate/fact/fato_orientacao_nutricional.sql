{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_nutritionorder') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by nutrition_order_id
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
        nutrition_order_id                                                  as id_orientacao,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        orderer_id                                                          as id_solicitante,
        {{ capitalize_name("split_part(orderer_name, ' - ', 1)") }}        as nome_solicitante,

        -- orientação
        instruction                                                         as instrucao,

        -- periodicidade traduzida
        case schedule_display
            when 'Habitual'  then 'Habitual'
            when 'Pontual'   then 'Pontual'
            else schedule_display
        end                                                                  as periodicidade,

        -- intent traduzido
        case intent
            when 'order' then 'Ordem'
            when 'plan'  then 'Plano'
            else intent
        end                                                                  as tipo_pedido,

        -- status traduzido
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

        -- data
        (datetime at time zone 'America/Sao_Paulo')::timestamp            as data_orientacao

    from mais_recente
)

select * from final
