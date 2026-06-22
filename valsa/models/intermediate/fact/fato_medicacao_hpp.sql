{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_medicationstatement') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by medication_statement_id
            order by
                delivery_date desc,
                date_asserted desc
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
        medication_statement_id                                             as id_uso_medicamento,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,

        information_source_id                                               as id_registrante,

        case information_source_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else information_source_type
        end                                                                  as tipo_registrante,

        {{ capitalize_name("information_source_name") }}                    as nome_registrante,

        -- medicamento
        medication_name                                                     as nome_medicamento,

        -- uso
        is_continuous                                                       as uso_continuo,
        dosage_text                                                         as posologia_texto,
        route                                                               as via_administracao,
        dose_value                                                          as valor_dose,
        dose_unit                                                           as unidade_dose,

        -- status
        case status
            when 'active'           then 'Ativo'
            when 'on-hold'          then 'Aguardando'
            when 'cancelled'        then 'Cancelado'
            when 'completed'        then 'Completo'
            when 'entered-in-error' then 'Erro'
            when 'stopped'          then 'Parado'
            when 'draft'            then 'Rascunho'
            when 'unknown'          then 'Desconhecido'
            else status
        end                                                                  as status,

        -- observação
        note                                                                 as observacao,

        -- data
        (date_asserted at time zone 'America/Sao_Paulo')::timestamp         as data_declaracao

    from mais_recente
)

select * from final
