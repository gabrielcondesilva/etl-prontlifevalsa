{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_observation_vital_signs') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by observation_id
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
        observation_id                                                      as id_medicao,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        performer_id                                                        as id_registrante,
        case performer_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else performer_type
        end                                                                  as tipo_registrante,
        {{ capitalize_name("split_part(performer_name, ' - ', 1)") }}      as nome_registrante,

        -- exame (nome traduzido)
        case measure_code
            when '85354-9'    then 'Pressão Arterial (sentado)'
            when '85354-9-d'  then 'Pressão Arterial (deitado)'
            when '8867-4'     then 'Frequência Cardíaca'
            when '9279-1'     then 'Frequência Respiratória'
            when '2708-6'     then 'Saturação O₂'
            when '8310-5'     then 'Temperatura'
            when '29463-7'    then 'Peso'
            when '8302-2'     then 'Altura'
            when '39156-5'    then 'IMC'
            when '15074-8'    then 'Glicemia'
            when '9843-4'     then 'Perímetro Cefálico'
            when 'LP31969-6'  then 'Circunferência Abdominal'
            when '62409-8'    then 'Circunferência Quadril'
            when '8277-6'     then 'Área de Superfície Corporal'
            else measure_name
        end                                                                  as nome_exame,

        -- valor simples
        value                                                               as valor,
        unit                                                                as unidade,

        -- pressão arterial (componentes)
        systolic_bp                                                        as pressao_sistolica,
        diastolic_bp                                                       as pressao_diastolica,
        mean_bp                                                             as pressao_media,
        bp_unit                                                             as unidade_pressao,

        -- status traduzido e data
        case status
            when 'registered'        then 'Registrado'
            when 'preliminary'       then 'Preliminar'
            when 'final'             then 'Final'
            when 'amended'           then 'Corrigido'
            when 'corrected'         then 'Corrigido'
            when 'cancelled'         then 'Cancelado'
            when 'entered-in-error'  then 'Erro de registro'
            when 'unknown'           then 'Desconhecido'
            else status
        end                                                                  as status,
        (effective_datetime at time zone 'America/Sao_Paulo')::timestamp  as data_medicao

    from mais_recente
)

select * from final
