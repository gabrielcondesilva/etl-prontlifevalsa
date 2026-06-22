{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_medicationrequest') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by medication_request_id
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
        medication_request_id                                               as id_prescricao,

        -- referências
        patient_id                                                          as id_paciente,
        case encounter_id
            when 'undefined' then null
            else encounter_id
        end                                                                  as id_atendimento,
        recorder_id                                                         as id_registrante,
        {{ capitalize_name("split_part(recorder_name, ' - ', 1)") }}        as nome_registrante,
        requester_id                                                        as id_solicitante,
        {{ capitalize_name("split_part(requester_name, ' - ', 1)") }}       as nome_solicitante,

        -- medicamento
        medication_name                                                     as nome_medicamento,

        -- categoria e tipo de terapia
        case therapy_type
            when 'continuous' then 'Contínuo'
            when 'acute'      then 'Agudo/Pontual'
            else therapy_type
        end                                                                  as tipo_terapia,
        prescription_type                                                   as tipo_receituario,

        -- posologia
        dosage_text                                                         as posologia_texto,
        route                                                               as via_administracao,
        dose_value                                                          as valor_dose,
        dose_unit                                                           as unidade_dose,
        frequency                                                           as frequencia,
        frequency_unit                                                      as unidade_frequencia,

        -- horário traduzido (mantém como está se não for um dos 3 períodos conhecidos)
        case schedule #>> '{}'
            when 'MORN'  then 'Manhã'
            when 'AFT'   then 'Tarde'
            when 'NIGHT' then 'Noite'
            else schedule #>> '{}'
        end                                                                  as horario,

        duration_value                                                      as valor_duracao,
        duration_unit                                                       as unidade_duracao,
        as_needed                                                           as uso_se_necessario,

        -- status traduzido
        case status
            when 'active'             then 'Ativa'
            when 'completed'          then 'Concluída'
            when 'cancelled'          then 'Cancelada'
            when 'stopped'            then 'Interrompida'
            when 'on-hold'            then 'Em espera'
            when 'entered-in-error'   then 'Erro de registro'
            when 'draft'              then 'Rascunho'
            else status
        end                                                                  as status,

        -- observação
        note                                                                 as observacao,

        -- data
        (authored_on at time zone 'America/Sao_Paulo')::timestamp         as data_prescricao

    from mais_recente
)

select * from final
