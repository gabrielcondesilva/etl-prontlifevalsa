{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_immunization') }}
),

-- camada 1: mais novo ganha por immunization_id (resolve múltiplas versões do mesmo registro)
numerado_id as (
    select
        *,
        row_number() over (
            partition by immunization_id
            order by delivery_date desc
        ) as rn_id
    from stg
),

mais_recente_id as (
    select *
    from numerado_id
    where rn_id = 1
),

-- camada 2: dedup por chave de negócio (resolve immunization_id diferentes para o mesmo evento)
numerado_negocio as (
    select
        *,
        row_number() over (
            partition by patient_id, vaccine_name, occurrence_datetime
            order by delivery_date desc
        ) as rn_negocio
    from mais_recente_id
),

final as (
    select
        -- chave
        immunization_id                                                     as id_vacina,

        -- referências
        patient_id                                                          as id_paciente,
        performer_id                                                        as id_registrante,
        case performer_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else performer_type
        end                                                                  as tipo_registrante,

        -- vacina
        vaccine_name                                                        as nome_vacina,

        -- status traduzido
        case status
            when 'completed'         then 'Completo'
            when 'entered-in-error'  then 'Erro de registro'
            when 'not-done'          then 'Não realizado'
            else status
        end                                                                  as status,

        -- observação (detalhe de dose/lote)
        note                                                                 as observacao,

        -- datas
        (recorded at time zone 'America/Sao_Paulo')::timestamp             as data_registro,
        (occurrence_datetime at time zone 'America/Sao_Paulo')::timestamp  as data_aplicacao

    from numerado_negocio
    where rn_negocio = 1
)

select * from final
