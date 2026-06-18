with source as (
    select * from {{ source('prontlife', 'questionnaire') }}
),

-- desdobra o item[] de topo
items_top as (
    select
        id                                                                  as questionnaire_id,
        data ->> 'title'                                                    as questionnaire_title,
        delivery_date,
        ingested_at,
        item.value                                                          as item_data,
        null::text                                                          as group_link_id,
        null::text                                                          as group_text
    from source,
         jsonb_array_elements(data -> 'item') as item
    where item.value ->> 'type' != 'group'

    union all

    -- desdobra perguntas dentro de grupos
    select
        id                                                                  as questionnaire_id,
        data ->> 'title'                                                    as questionnaire_title,
        delivery_date,
        ingested_at,
        sub_item.value                                                      as item_data,
        grp.value ->> 'linkId'                                             as group_link_id,
        grp.value ->> 'text'                                               as group_text
    from source,
         jsonb_array_elements(data -> 'item') as grp
       , jsonb_array_elements(grp.value -> 'item') as sub_item
    where grp.value ->> 'type' = 'group'
),

renamed as (
    select
        -- chaves
        questionnaire_id,
        questionnaire_title,
        item_data ->> 'linkId'                                             as link_id,

        -- grupo (se a pergunta estiver dentro de um grupo)
        group_link_id,
        group_text,

        -- dados da pergunta
        item_data ->> 'text'                                               as question_text,
        item_data ->> 'type'                                               as question_type,
        (item_data ->> 'required')::boolean                                as required,
        (item_data ->> 'repeats')::boolean                                 as repeats,

        -- metadados
        delivery_date,
        ingested_at

    from items_top
)

select * from renamed
