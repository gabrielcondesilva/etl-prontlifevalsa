with source as (
    select * from {{ source('prontlife', 'observation') }}
),

imaging as (
    select *
    from source
    where data -> 'category' -> 0 -> 'coding' -> 0 ->> 'code' = 'imaging'
),

renamed as (
    select
        -- chaves
        id                                                                  as observation_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'encounter' ->> 'reference', 'Encounter/', '')     as encounter_id,
        split_part(data -> 'performer' -> 0 ->> 'reference', '/', 2)       as performer_id,
        split_part(data -> 'performer' -> 0 ->> 'reference', '/', 1)       as performer_type,
        data -> 'performer' -> 0 ->> 'display'                             as performer_name,

        -- exame
        data -> 'code' ->> 'text'                                           as exam_name,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%prontlife.com.br/exame%'
            limit 1
        )                                                                   as exam_code,
        (
            select item ->> 'code'
            from jsonb_array_elements(data -> 'code' -> 'coding') as item
            where item ->> 'system' like '%TUSS%'
            limit 1
        )                                                                   as tuss_code,

        -- laudo (texto livre — sensível LGPD)
        data -> 'note' -> 0 ->> 'text'                                     as report_text,

        -- anexo PDF
        data -> 'contained' -> 0 -> 'content' -> 0
            -> 'attachment' ->> 'url'                                       as attachment_url,
        data -> 'contained' -> 0 -> 'content' -> 0
            -> 'attachment' ->> 'title'                                     as attachment_title,

        -- status e datas
        data ->> 'status'                                                   as status,
        (data ->> 'issued')::timestamptz                                    as issued,
        (data ->> 'effectiveDateTime')::timestamptz                         as effective_datetime,

        -- metadados
        delivery_date,
        ingested_at

    from imaging
)

select * from renamed
