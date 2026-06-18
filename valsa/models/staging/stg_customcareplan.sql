with source as (
    select * from {{ source('prontlife', 'customcareplan') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as care_plan_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,

        -- author pode ser Practitioner ou Device — guarda referência completa
        data -> 'author' ->> 'reference'                                    as author_reference,
        data -> 'author' ->> 'display'                                      as author_name,

        -- programa
        replace(
            data -> 'customEpisodeOfCare' ->> 'reference',
            'CustomEpisodeOfCare/', ''
        )                                                                   as episode_of_care_id,

        -- definição do plano (primeiro do array)
        replace(
            data -> 'customPlanDefinition' -> 0 ->> 'reference',
            'CustomPlanDefinition/', ''
        )                                                                   as plan_definition_id,

        -- escore de risco de origem (primeiro do array)
        replace(
            data -> 'originatingSource' -> 0 ->> 'reference',
            'RiskAssessment/', ''
        )                                                                   as risk_assessment_id,

        -- organização
        replace(
            data -> 'managingOrganization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- dados do plano
        data ->> 'title'                                                    as title,
        data ->> 'status'                                                   as status,
        data ->> 'objective'                                                as objective,
        (data ->> 'linkingWindow')::integer                                 as linking_window,
        (data ->> 'automaticLinking')::boolean                              as automatic_linking,

        -- período
        (data -> 'period' ->> 'start')::timestamptz                        as period_start,
        (data -> 'period' ->> 'end')::timestamptz                          as period_end,

        -- identificador externo (sistema pode variar)
        data -> 'identifier' -> 0 ->> 'value'                              as external_id,
        data -> 'identifier' -> 0 ->> 'system'                             as external_id_system,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
