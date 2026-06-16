with source as (
    select * from {{ source('prontlife', 'practitioner') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as practitioner_id,

        -- nome
        data -> 'name' -> 0 ->> 'text'                                     as full_name,

        -- dados básicos
        data ->> 'gender'                                                   as gender,
        (data ->> 'birthDate')::date                                        as birth_date,

        -- contatos
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'email'
            limit 1
        )                                                                   as email,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'phone'
            limit 1
        )                                                                   as phone,

        -- endereço
        (
            select item ->> 'text'
            from jsonb_array_elements(data -> 'address') as item
            limit 1
        )                                                                   as address_text,
        (
            select item ->> 'city'
            from jsonb_array_elements(data -> 'address') as item
            limit 1
        )                                                                   as city,
        (
            select item ->> 'state'
            from jsonb_array_elements(data -> 'address') as item
            limit 1
        )                                                                   as state,
        (
            select item ->> 'district'
            from jsonb_array_elements(data -> 'address') as item
            limit 1
        )                                                                   as district,
        (
            select item ->> 'postalCode'
            from jsonb_array_elements(data -> 'address') as item
            limit 1
        )                                                                   as postal_code,

        -- identificadores
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CPF'
            limit 1
        )                                                                   as cpf,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:RG'
            limit 1
        )                                                                   as rg,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CNS'
            limit 1
        )                                                                   as cns,

        -- qualificações
        (
            select qual -> 'code' -> 'coding' -> 0 ->> 'display'
            from jsonb_array_elements(data -> 'qualification') as qual
            where qual -> 'code' -> 'coding' -> 0 ->> 'system'
                like '%prontlife%'
            limit 1
        )                                                                   as specialty,
        (
            select ident ->> 'value'
            from jsonb_array_elements(data -> 'qualification') as qual,
                 jsonb_array_elements(qual -> 'identifier') as ident
            where ident ->> 'system' like 'urn:C%'
            limit 1
        )                                                                   as council_number,
        (
            select replace(ident ->> 'system', 'urn:', '')
            from jsonb_array_elements(data -> 'qualification') as qual,
                 jsonb_array_elements(qual -> 'identifier') as ident
            where ident ->> 'system' like 'urn:C%'
            limit 1
        )                                                                   as council_type,
        (
            select ident ->> 'value'
            from jsonb_array_elements(data -> 'qualification') as qual,
                 jsonb_array_elements(qual -> 'identifier') as ident
            where ident ->> 'system' = 'urn:RQE'
            limit 1
        )                                                                   as rqe,

        -- extensões
        (
            select replace(ext -> 'valueReference' ->> 'reference', 'Organization/', '')
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%managing-organization%'
            limit 1
        )                                                                   as organization_id,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%has-user%'
            limit 1
        )                                                                   as has_user,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
