with source as (
    select * from {{ source('prontlife', 'questionnaire') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as questionnaire_id,

        -- dados do questionário
        data ->> 'title'                                                    as title,
        data ->> 'status'                                                   as status,
        data ->> 'description'                                              as description,
        data ->> 'publisher'                                                as publisher,

        -- extensões
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%category%'
            limit 1
        )                                                                   as category,
        (
            select ext ->> 'valueString'
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%card%'
            limit 1
        )                                                                   as card,
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%prevent-printing%'
            limit 1
        )                                                                   as prevent_printing,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
