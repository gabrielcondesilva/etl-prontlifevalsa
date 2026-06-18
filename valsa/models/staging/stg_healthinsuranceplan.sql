with source as (
    select * from {{ source('prontlife', 'healthinsuranceplan') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as healthinsuranceplan_id,

        -- referências
        replace(
            data -> 'healthInsurance' ->> 'reference', 'HealthInsurance/', ''
        )                                                                   as healthinsurance_id,
        replace(
            data -> 'managingOrganization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- dados do plano
        data ->> 'name'                                                     as name,
        data ->> 'ansCode'                                                  as ans_code,
        data ->> 'status'                                                   as status,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
