with source as (
    select * from {{ source('prontlife', 'nutritionorder') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as nutrition_order_id,

        -- paciente
        replace(data -> 'patient' ->> 'reference', 'Patient/', '')         as patient_id,
        data -> 'patient' ->> 'display'                                     as patient_name,

        -- prescritor
        replace(data -> 'orderer' ->> 'reference', 'Practitioner/', '')    as orderer_id,
        data -> 'orderer' ->> 'display'                                     as orderer_name,

        -- atendimento
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,

        -- orientação nutricional
        data -> 'oralDiet' ->> 'instruction'                                as instruction,
        data -> 'oralDiet' -> 'schedule' -> 0 -> 'code' -> 'coding' -> 0 ->> 'code'
                                                                            as schedule_code,
        data -> 'oralDiet' -> 'schedule' -> 0 -> 'code' -> 'coding' -> 0 ->> 'display'
                                                                            as schedule_display,

        -- intent e status
        data ->> 'intent'                                                   as intent,
        data ->> 'status'                                                   as status,

        -- data
        (data ->> 'dateTime')::timestamptz                                  as datetime,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
