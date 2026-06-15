with source as (
    select * from {{ source('prontlife', 'patient') }}
),

renamed as (
    select
        -- chaves
        id                                                              as patient_id,

        -- metadados da entrega
        source_file,
        delivery_date,
        ingested_at,

        -- nome
        data -> 'name' -> 0 ->> 'text'                                 as full_name,

        -- dados básicos
        data ->> 'gender'                                              as gender,
        (data ->> 'birthDate')::date                                   as birth_date,

        -- estado civil
        data -> 'maritalStatus' -> 'coding' -> 0 ->> 'code'           as marital_status_code,
        data -> 'maritalStatus' -> 'coding' -> 0 ->> 'display'        as marital_status,

        -- contatos
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'email'
            limit 1
        )                                                               as email,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'phone'
              and item ->> 'use'    = 'home'
            limit 1
        )                                                               as phone_home,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'telecom') as item
            where item ->> 'system' = 'phone'
              and item ->> 'use'    = 'mobile'
            limit 1
        )                                                               as phone_mobile,

        -- endereço
        (
            select item ->> 'text'
            from jsonb_array_elements(data -> 'address') as item
            where item ->> 'use' = 'home'
            limit 1
        )                                                               as address_text,
        (
            select item ->> 'city'
            from jsonb_array_elements(data -> 'address') as item
            where item ->> 'use' = 'home'
            limit 1
        )                                                               as city,
        (
            select item ->> 'state'
            from jsonb_array_elements(data -> 'address') as item
            where item ->> 'use' = 'home'
            limit 1
        )                                                               as state,
        (
            select item ->> 'district'
            from jsonb_array_elements(data -> 'address') as item
            where item ->> 'use' = 'home'
            limit 1
        )                                                               as district,
        (
            select item ->> 'postalCode'
            from jsonb_array_elements(data -> 'address') as item
            where item ->> 'use' = 'home'
            limit 1
        )                                                               as postal_code,

        -- identificadores
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CPF'
            limit 1
        )                                                               as cpf,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:RG'
            limit 1
        )                                                               as rg,
        (
            select item ->> 'value'
            from jsonb_array_elements(data -> 'identifier') as item
            where item ->> 'system' = 'urn:CNS'
            limit 1
        )                                                               as cns,

        -- extensões
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-mothersMaidenName%'
            limit 1
        )                                                               as mothers_name,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%fatherName%'
            limit 1
        )                                                               as fathers_name,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%gender-identity%'
            limit 1
        )                                                               as gender_identity,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%social-name%'
            limit 1
        )                                                               as social_name,
        (
            select item -> 'valueCodeableConcept' -> 'coding' -> 0 ->> 'display'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-race%'
            limit 1
        )                                                               as race,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%extension-patient-birthplace%'
            limit 1
        )                                                               as nationality,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-birth-state%'
            limit 1
        )                                                               as birth_state,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-birth-city%'
            limit 1
        )                                                               as birth_city,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%profession%'
            limit 1
        )                                                               as profession,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-guardian-name%'
            limit 1
        )                                                               as guardian_name,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-guardian-cpf%'
            limit 1
        )                                                               as guardian_cpf,
        (
            select item ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as item
            where item ->> 'url' like '%patient-guardian-relationship%'
            limit 1
        )                                                               as guardian_relationship

    from source
)

select * from renamed
