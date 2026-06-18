with source as (
    select * from {{ source('prontlife', 'customplandefinition') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as plan_definition_id,

        -- dados do plano
        data ->> 'title'                                                    as title,
        data ->> 'status'                                                   as status,

        -- organização
        replace(
            data -> 'managingOrganization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- questionário associado (campo source[], não documentado)
        data -> 'source' -> 0 -> 'questionnaire' -> 0 ->> 'reference'      as questionnaire_reference,

        -- arrays complexos guardados como JSONB (desdobrar na intermediate se precisar)
        data -> 'preRequisite'                                              as pre_requisite,
        data -> 'groupedAction'                                             as grouped_action,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
