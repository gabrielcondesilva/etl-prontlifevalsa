{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact']
    )
}}

with stg as (
    select * from {{ ref('stg_familymemberhistory') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by family_history_id
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
        family_history_id as id_historico_familiar,

        -- referências
        patient_id as id_paciente,

        case encounter_id
            when 'undefined' then null
            else encounter_id
        end as id_atendimento,

        case
            when provider_id like 'Patient/%'
                then split_part(provider_id, '/', 2)
            else provider_id
        end as id_registrante,

        case
            when provider_id like 'Patient/%' then 'Paciente'
            when provider_id is not null then 'Profissional'
            else null
        end as tipo_registrante,

        {{ capitalize_name("provider_name") }} as nome_registrante,

        -- histórico familiar
        case relationship_code
            when 'FAMMEMB' then 'Familiar'
            when 'MTH'     then 'Mãe'
            when 'FTH'     then 'Pai'
            when 'SIB'     then 'Irmão/Irmã'
            when 'BRO'     then 'Irmão'
            when 'SIS'     then 'Irmã'
            when 'GRMTH'   then 'Avó'
            when 'GRFTH'   then 'Avô'
            when 'AUNT'    then 'Tia'
            when 'UNCLE'   then 'Tio'
            else relationship_code
        end as parentesco,

        condition_name as condicao,
        cid10_code as cid10,
        cid10_display as descricao_cid10,
        note_text as observacao,

        -- status
        case status
            when 'completed' then 'Completo'
            when 'partial'   then 'Parcial'
            when 'entered-in-error' then 'Erro'
            when 'health-unknown' then 'Desconhecido'
            else status
        end as status,

        case verification_status
            when 'confirmed'   then 'Confirmado'
            when 'unconfirmed' then 'Não confirmado'
            when 'provisional' then 'Provisório'
            else verification_status
        end as status_verificacao,

        -- data
        (recorded_date at time zone 'America/Sao_Paulo')::timestamp as data_registro

    from mais_recente
)

select * from final
