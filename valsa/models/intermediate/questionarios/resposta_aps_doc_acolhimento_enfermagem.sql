{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact', 'questionario']
    )
}}

with stg as (
    select * from {{ ref('stg_response_aps_doc_acolhimento_enfermagem') }}
),

ultima_entrega_por_resposta as (
    select
        response_id,
        max(delivery_date) as max_delivery_date
    from stg
    group by response_id
),

mais_recente as (
    select stg.*
    from stg
    inner join ultima_entrega_por_resposta u
        on stg.response_id = u.response_id
        and stg.delivery_date = u.max_delivery_date
),

final as (
    select
        response_item_id                                                    as id_resposta_item,
        response_id                                                         as id_resposta,

        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        author_id                                                           as id_autor,
        case author_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else author_type
        end                                                                  as tipo_autor,
        {{ capitalize_name("split_part(author_display, ' - ', 1)") }}      as nome_autor,

        '484b9ee2-1b52-4a1c-b026-11331bce3018'                              as id_questionario,

        link_id                                                             as id_pergunta,
        question_text                                                       as texto_pergunta,
        parent_link_id                                                      as id_grupo,
        parent_text                                                         as nome_grupo,
        depth                                                                as profundidade,
        answer_seq                                                          as sequencia_resposta,

        value_string                                                        as resposta_texto,
        value_coding_code                                                   as resposta_codigo,
        value_coding_display                                                as resposta_escolha,
        value_date                                                          as resposta_data,
        value_quantity_value                                                as resposta_quantidade_valor,
        value_quantity_unit                                                 as resposta_quantidade_unidade,
        value_integer                                                       as resposta_inteiro,
        value_decimal                                                       as resposta_decimal,

        case status
            when 'completed'         then 'Concluído'
            when 'in-progress'       then 'Em andamento'
            when 'entered-in-error'  then 'Erro de registro'
            else status
        end                                                                  as status,

        (authored_at at time zone 'America/Sao_Paulo')::timestamp         as data_resposta

    from mais_recente
)

select * from final
