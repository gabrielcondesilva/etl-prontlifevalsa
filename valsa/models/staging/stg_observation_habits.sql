with source as (
    select * from {{ source('prontlife', 'observation') }}
),

habits as (
    select *
    from source
    where data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code' = 'social-history'
),

renamed as (
    select
        -- chaves
        id                                                                  as observation_id,

        -- paciente
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,

        -- atendimento
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,

        -- performer (primeiro do array)
        replace(
            data -> 'performer' -> 0 ->> 'reference', 'Practitioner/', ''
        )                                                                   as performer_id,
        data -> 'performer' -> 0 ->> 'display'                             as performer_name,

        -- tipo de hábito
        data -> 'code' -> 'coding' -> 0 ->> 'code'                         as habit_type_code,
        data -> 'code' ->> 'text'                                           as habit_type_name,

        -- valor do hábito
        data -> 'valueCodeableConcept' ->> 'text'                           as habit_value,
        data -> 'valueCodeableConcept' -> 'coding' -> 0 ->> 'code'         as habit_value_code,
        data -> 'valueCodeableConcept' -> 'coding' -> 0 ->> 'display'      as habit_value_display,

        -- componentes numéricos (tabagismo/etilismo)
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = 'cigarros-por-dia'
            limit 1
        )                                                                   as cigarettes_per_day,
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = 'periodo-anos'
            limit 1
        )                                                                   as smoking_years,
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = 'macos-anos'
            limit 1
        )                                                                   as packs_per_year,
        (
            select (comp -> 'valueQuantity' ->> 'value')::numeric
            from jsonb_array_elements(data -> 'component') as comp
            where comp -> 'code' -> 'coding' -> 0 ->> 'code' = 'doses-por-semana'
            limit 1
        )                                                                   as alcohol_doses_per_week,

        -- observação
        data -> 'note' -> 0 ->> 'text'                                     as note_text,
        (data -> 'note' -> 0 ->> 'time')::timestamptz                      as note_time,
        replace(
            data -> 'note' -> 0 -> 'authorReference' ->> 'reference',
            'Practitioner/', ''
        )                                                                   as note_author_id,

        -- status e data
        data ->> 'status'                                                   as status,
        (data ->> 'issued')::timestamptz                                    as issued,

        -- metadados
        delivery_date,
        ingested_at

    from habits
)

select * from renamed
