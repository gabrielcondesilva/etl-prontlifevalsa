{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_allergyintolerance') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by allergy_id
            order by
                delivery_date desc,
                recorded_date desc
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
        allergy_id as id_alergia_intolerancia,

        -- referências
        patient_id as id_paciente,

        case encounter_id
            when 'undefined' then null
            else encounter_id
        end as id_atendimento,

        recorder_id as id_registrante,

        case recorder_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else recorder_type
        end as tipo_registrante,

        {{ capitalize_name("recorder_name") }} as nome_registrante,

        -- alergia/intolerância
        case allergy_type
            when 'allergy'     then 'Alergia'
            when 'intolerance' then 'Intolerância'
            else allergy_type
        end as tipo_alergia,

        coalesce(
            nullif(substance_name, ''),
            nullif(substance_display, '')
        ) as nome_substancia,

        -- status
        case clinical_status
            when 'active' then 'Ativo'
            else clinical_status
        end as status_clinico,

        case verification_status
            when 'confirmed'   then 'Confirmado'
            when 'unconfirmed' then 'Não confirmado'
            else verification_status
        end as status_verificacao,

        -- observação
        note_text as observacao,

        -- data
        (recorded_date at time zone 'America/Sao_Paulo')::timestamp as data_registro

    from mais_recente
)

select * from final
