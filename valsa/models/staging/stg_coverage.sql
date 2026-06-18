with source as (
    select * from {{ source('prontlife', 'coverage') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as coverage_id,

        -- identificador externo
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:externalID'
            limit 1
        )                                                                   as external_id,

        -- pacientes
        replace(data -> 'subscriber' ->> 'reference', 'Patient/', '')      as subscriber_patient_id,
        replace(data -> 'beneficiary' ->> 'reference', 'Patient/', '')     as beneficiary_patient_id,

        -- convênio
        replace(
            data -> 'payor' -> 0 ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,
        data -> 'payor' -> 0 ->> 'display'                                 as payor_name,

        -- plano
        data -> 'class' -> 0 ->> 'name'                                    as plan_name,
        data -> 'class' -> 0 ->> 'value'                                   as plan_id,

        -- código ANS (extensão dentro do class[])
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(
                data -> 'class' -> 0 -> 'extension'
            ) as ext
            where ext ->> 'url' like '%ans-code%'
            limit 1
        )                                                                   as ans_code,

        -- carteira
        data ->> 'dependent'                                                as dependent_card_number,
        data ->> 'subscriberId'                                             as subscriber_card_number,

        -- status e validade
        data ->> 'status'                                                   as status,
        (data -> 'period' ->> 'start')::date                               as period_start,
        (data -> 'period' ->> 'end')::date                                 as period_end,

        -- extensão
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%coverage-validate%'
            limit 1
        )                                                                   as coverage_validate,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
