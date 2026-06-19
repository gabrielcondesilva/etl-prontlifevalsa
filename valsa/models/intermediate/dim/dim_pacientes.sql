{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dimension']
    )
}}

with stg as (
    select * from {{ ref('stg_patient') }}
),

numerado as (
    select
        *,
        row_number() over (
            partition by patient_id
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
        patient_id                                                          as id_paciente,

        -- nome (capitalizado corretamente)
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
        phone_mobile                                                        as telefone_celular,
        lower(email)                                                        as email,

        -- localização (bairro, cidade, estado)
        {{ capitalize_name('district') }}                                   as bairro,
        {{ capitalize_name('city') }}                                       as cidade,
        upper(state)                                                        as estado

    from mais_recente
)

select * from final
