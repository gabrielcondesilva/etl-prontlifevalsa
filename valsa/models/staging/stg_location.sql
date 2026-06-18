with source as (
    select * from {{ source('prontlife', 'location') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as location_id,

        -- nome
        data ->> 'name'                                                     as name,
        data -> 'alias' -> 0 ->> 0                                         as alias,

        -- status
        data ->> 'status'                                                   as status,

        -- contatos
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'phone'
            limit 1
        )                                                                   as phone,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'sms'
            limit 1
        )                                                                   as sms,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'email'
            limit 1
        )                                                                   as email,

        -- endereço (objeto direto, não array)
        data -> 'address' ->> 'text'                                        as address_text,
        data -> 'address' ->> 'city'                                        as city,
        data -> 'address' ->> 'state'                                       as state,
        data -> 'address' ->> 'district'                                    as district,
        data -> 'address' ->> 'country'                                     as country,
        data -> 'address' ->> 'postalCode'                                  as postal_code,

        -- extensões do endereço (array dentro do objeto address)
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'address' -> 'extension') as ext
            where ext ->> 'url' like '%address-region%'
            limit 1
        )                                                                   as address_region,
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'address' -> 'extension') as ext
            where ext ->> 'url' like '%codigo-ibge-municipio%'
            limit 1
        )                                                                   as ibge_code,

        -- identificadores
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CNES'
            limit 1
        )                                                                   as cnes,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CNPJ'
            limit 1
        )                                                                   as cnpj,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CPF'
            limit 1
        )                                                                   as cpf,

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
