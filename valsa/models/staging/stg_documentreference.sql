with source as (
    select * from {{ source('prontlife', 'documentreference') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as document_id,

        -- paciente
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        data -> 'subject' ->> 'display'                                     as patient_name,

        -- autor (primeiro do array)
        replace(
            data -> 'author' -> 0 ->> 'reference', 'Practitioner/', ''
        )                                                                   as author_id,
        data -> 'author' -> 0 ->> 'display'                                 as author_name,

        -- contexto
        replace(
            data -> 'context' -> 'encounter' -> 0 ->> 'reference',
            'Encounter/', ''
        )                                                                   as encounter_id,
        replace(
            data -> 'context' -> 'related' -> 0 ->> 'reference',
            'QuestionnaireResponse/', ''
        )                                                                   as questionnaire_response_id,

        -- tipo de documento
        coalesce(
            data -> 'type' ->> 'text',
            data -> 'type' -> 'coding' -> 0 ->> 'display'
        )                                                                   as document_type,
        data -> 'type' -> 'coding' -> 0 ->> 'code'                         as document_type_code,

        -- categoria
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'               as category_code,
        data -> 'category' -> 0 -> 'coding' -> 0 ->> 'display'             as category_display,

        -- conteúdo (texto do atestado/relatório)
        data -> 'content' -> 0 -> 'attachment' ->> 'title'                 as content_title,

        -- descrição, status e data
        data ->> 'description'                                              as description,
        data ->> 'status'                                                   as status,
        data ->> 'docStatus'                                                 as doc_status,
        (data ->> 'date')::timestamptz                                      as date,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
