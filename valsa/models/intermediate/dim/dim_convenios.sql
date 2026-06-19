{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dimension']
    )
}}

with stg as (
    select * from {{ ref('stg_coverage') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by coverage_id
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
        coverage_id                                                         as id_convenio,

        -- pacientes envolvidos
        subscriber_patient_id                                               as id_paciente_titular,
        beneficiary_patient_id                                              as id_paciente_beneficiario,

        -- plano e operadora
        payor_name                                                          as nome_operadora,
        plan_name                                                           as nome_plano,

        -- carteirinhas
        dependent_card_number                                               as numero_carteira_dependente,
        subscriber_card_number                                              as numero_carteira_titular,

        -- status traduzido
        case status
            when 'active'           then 'Ativo'
            when 'cancelled'        then 'Cancelado'
            when 'draft'            then 'Rascunho'
            when 'entered-in-error' then 'Erro de registro'
            else status
        end                                                                  as status,

        -- vigência
        period_start                                                        as data_inicio_vigencia,
        period_end                                                          as data_fim_vigencia

    from mais_recente
)

select * from final
