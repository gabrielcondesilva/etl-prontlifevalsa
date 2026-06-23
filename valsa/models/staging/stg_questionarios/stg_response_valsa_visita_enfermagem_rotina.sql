{{
    config(
        materialized = 'view'
    )
}}

with recursive recursivo as (
    select
        s.id                                                                as response_id,
        s.data -> 'subject' ->> 'reference'                                as patient_ref,
        s.data -> 'encounter' ->> 'reference'                              as encounter_ref,
        s.data -> 'author' ->> 'reference'                                 as author_ref,
        s.data -> 'author' ->> 'display'                                   as author_display,
        s.data ->> 'status'                                                 as status,
        s.data ->> 'authored'                                               as authored,
        item.value                                                          as item_data,
        null::text                                                          as parent_link_id,
        null::text                                                          as parent_text,
        0                                                                    as depth,
        s.delivery_date,
        s.ingested_at
    from {{ source('prontlife', 'questionnaire_response') }} s,
         jsonb_array_elements(s.data -> 'item') as item
    where s.data ->> 'questionnaire' = 'Questionnaire/c28c22e4-cffb-4d18-9179-cba70287e727'

    union all

    select
        r.response_id,
        r.patient_ref,
        r.encounter_ref,
        r.author_ref,
        r.author_display,
        r.status,
        r.authored,
        sub_item.value,
        r.item_data ->> 'linkId',
        r.item_data ->> 'text',
        r.depth + 1,
        r.delivery_date,
        r.ingested_at
    from recursivo r,
         jsonb_array_elements(r.item_data -> 'item') as sub_item
    where r.item_data -> 'item' is not null
),

folhas as (
    select *
    from recursivo
    where item_data -> 'item' is null
),

desdobrado_resposta as (
    select
        folhas.*,
        answer.value                                                       as answer_data,
        answer.ordinality                                                  as answer_seq
    from folhas
    left join lateral jsonb_array_elements(folhas.item_data -> 'answer')
        with ordinality as answer(value, ordinality)
        on true
)

select
    response_id,
    replace(patient_ref, 'Patient/', '')                                   as patient_id,
    replace(encounter_ref, 'Encounter/', '')                               as encounter_id,
    split_part(author_ref, '/', 2)                                         as author_id,
    split_part(author_ref, '/', 1)                                         as author_type,
    author_display,
    status,
    authored::timestamptz                                                  as authored_at,

    item_data ->> 'linkId'                                                 as link_id,
    item_data ->> 'text'                                                   as question_text,
    parent_link_id,
    parent_text,
    depth,
    coalesce(answer_seq, 1)                                                as answer_seq,

    response_id || '-' || (item_data ->> 'linkId') || '-' || coalesce(answer_seq, 1)::text
                                                                            as response_item_id,

    answer_data ->> 'valueString'                                          as value_string,
    answer_data -> 'valueCoding' ->> 'code'                                as value_coding_code,
    answer_data -> 'valueCoding' ->> 'display'                             as value_coding_display,
    answer_data ->> 'valueDate'                                            as value_date,
    (answer_data -> 'valueQuantity' ->> 'value')::numeric                  as value_quantity_value,
    answer_data -> 'valueQuantity' ->> 'unit'                              as value_quantity_unit,
    (answer_data ->> 'valueInteger')::int                                  as value_integer,
    (answer_data ->> 'valueDecimal')::numeric                              as value_decimal,

    delivery_date,
    ingested_at

from desdobrado_resposta
