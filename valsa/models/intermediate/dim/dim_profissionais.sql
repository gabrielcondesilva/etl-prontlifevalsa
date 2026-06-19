{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dimension']
    )
}}

with stg as (
    select * from {{ ref('stg_practitioner') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by practitioner_id
            order by delivery_date desc
        ) as rn
    from stg
),

mais_recente as (
    select *
    from numerado
    where rn = 1
),

final as (
    select
        -- chave
        practitioner_id                                                     as id_profissional,

        -- nome
        {{ capitalize_name('full_name') }}                                  as nome_completo,

        -- sexo traduzido
        case gender
            when 'male'   then 'Masculino'
            when 'female' then 'Feminino'
            else gender
        end                                                                  as sexo,

        -- nascimento e idade
        birth_date                                                          as data_nascimento,
        extract(year from age(current_date, birth_date))::integer           as idade,

        -- documento
        trim(cpf)                                                           as cpf,

        -- contato
        phone                                                               as telefone,
        lower(email)                                                        as email,

        -- atuação profissional
        specialty                                                           as especialidade,
        council_number                                                      as numero_conselho,
        council_type                                                        as tipo_conselho

    from mais_recente
)

select * from final
