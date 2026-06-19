with source as (
    select * from {{ source('prontlife', 'userparameter_mandatory_fields') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as user_parameter_id,

        -- dados do parâmetro
        data ->> 'name'                                                     as name,
        data ->> 'type'                                                     as type,
        data ->> 'value'                                                    as value,
        data ->> 'category'                                                 as category,

        -- organização
        replace(
            data -> 'organization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
