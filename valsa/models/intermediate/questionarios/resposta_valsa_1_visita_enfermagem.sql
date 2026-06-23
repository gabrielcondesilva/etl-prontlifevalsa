{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'fact', 'questionario']
    )
}}

with stg as (
    select * from {{ ref('stg_response_valsa_1_visita_enfermagem') }}
),

ultima_entrega_por_resposta as (
    select
        response_id,
        max(delivery_date) as max_delivery_date
    from stg
    group by response_id
),

candidatos as (
    select stg.*
    from stg
    inner join ultima_entrega_por_resposta u
        on stg.response_id = u.response_id
        and stg.delivery_date = u.max_delivery_date
),

desempate as (
    select
        *,
        row_number() over (
            partition by response_id, link_id, answer_seq
            order by
                case status
                    when 'completed'         then 1
                    when 'in-progress'       then 2
                    when 'entered-in-error'  then 3
                    else 4
                end
        ) as rn_status
    from candidatos
),

mais_recente as (
    select *
    from desempate
    where rn_status = 1
),

final as (
    select
        -- chave
        response_item_id                                                    as id_resposta_item,
        response_id                                                         as id_resposta,

        -- referências
        patient_id                                                          as id_paciente,
        encounter_id                                                        as id_atendimento,
        author_id                                                           as id_autor,
        case author_type
            when 'Practitioner' then 'Profissional'
            when 'Patient'      then 'Paciente'
            else author_type
        end                                                                  as tipo_autor,
        {{ capitalize_name("split_part(author_display, ' - ', 1)") }}      as nome_autor,

        -- questionário
        'd4615956-673b-4826-bcac-32da27ea6a0a'                              as id_questionario,

        -- pergunta
        link_id                                                             as id_pergunta,
        question_text                                                       as texto_pergunta,
        parent_link_id                                                      as id_grupo,
        parent_text                                                         as nome_grupo,
        depth                                                                as profundidade,
        answer_seq                                                          as sequencia_resposta,

        -- resposta
        value_string                                                        as resposta_texto,
        value_coding_code                                                   as resposta_codigo,
        value_coding_display                                                as resposta_escolha,
        value_date                                                          as resposta_data,
        value_quantity_value                                                as resposta_quantidade_valor,
        value_quantity_unit                                                 as resposta_quantidade_unidade,
        value_integer                                                       as resposta_inteiro,
        value_decimal                                                       as resposta_decimal,

        -- status traduzido
        case status
            when 'completed'         then 'Concluído'
            when 'in-progress'       then 'Em andamento'
            when 'entered-in-error'  then 'Erro de registro'
            else status
        end                                                                  as status,

        -- data
        (authored_at at time zone 'America/Sao_Paulo')::timestamp         as data_resposta

    from mais_recente
)

select * from final
