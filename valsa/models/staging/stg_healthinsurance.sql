with source as (
    select * from {{ source('prontlife', 'healthinsurance') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as healthinsurance_id,

        -- dados do convênio
        data ->> 'name'                                                     as name,
        data ->> 'corporateName'                                            as corporate_name,
        data ->> 'ansCode'                                                  as ans_code,
        data ->> 'status'                                                   as status,

        -- organização
        replace(
            data -> 'managingOrganization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
