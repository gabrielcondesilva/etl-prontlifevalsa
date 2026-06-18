with source as (
    select * from {{ source('prontlife', 'customcareplanaction') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as care_plan_action_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(
            data -> 'customCarePlan' ->> 'reference', 'CustomCarePlan/', ''
        )                                                                   as care_plan_id,
        replace(
            data -> 'reference' ->> 'reference', 'Appointment/', ''
        )                                                                   as appointment_id,
        replace(
            data -> 'managingOrganization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- ação
        data -> 'action' ->> 'code'                                         as action_code,

        -- status e origem
        data ->> 'status'                                                   as status,
        data ->> 'origin'                                                   as origin,

        -- datas
        (data ->> 'dateTime')::timestamptz                                  as datetime,
        (data ->> 'planningDateTime')::timestamptz                          as planning_datetime,

        -- identificador externo
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:externalID'
            limit 1
        )                                                                   as external_id,

        -- observações
        data ->> 'annotation'                                               as annotation,
        data ->> 'observation'                                              as observation,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
