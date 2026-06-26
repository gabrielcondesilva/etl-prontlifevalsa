{{
    config(
        materialized = 'table',
        tags = ['intermediate', 'dimension']
    )
}}

with stg as (
    select * from {{ ref('stg_coverage') }}
),

pacientes_programa as (
    select distinct id_paciente
    from {{ ref('fato_programas') }}
),

carteiras_do_programa as (
    select sc.*
    from stg sc
    inner join pacientes_programa pp
        on sc.beneficiary_patient_id = pp.id_paciente
),

-- Passo 1: limpeza estrutural da carteira (espaco, aspas, tabulacao, texto colado)
card_passo1 as (
    select
        *,
        trim(
            replace(replace(dependent_card_number, '"', ''), chr(9), '')
        ) as card_limpo_1
    from carteiras_do_programa
),

card_passo2 as (
    select
        *,
        -- remove texto descritivo colado (ex: "01006589100 Tipo:Titular")
        case
            when card_limpo_1 ~ '^\S+\s+[A-Za-zÀ-ú]'
            then split_part(card_limpo_1, ' ', 1)
            else card_limpo_1
        end as card_limpo_2
    from card_passo1
),

card_passo3 as (
    select
        *,
        -- corta concatenacao "valor1 / valor2" -> mantem so o primeiro
        trim(split_part(card_limpo_2, '/', 1)) as card_limpo_3
    from card_passo2
),

card_passo4 as (
    select
        *,
        -- corta concatenacao "valor1 - valor2" (hifen com espaco) -> mantem so o primeiro
        trim(
            case
                when card_limpo_3 ~ '\s-\s'
                then split_part(card_limpo_3, '-', 1)
                else card_limpo_3
            end
        ) as card_limpo_4
    from card_passo3
),

-- Passo 2: validacao final + remocao de zero a esquerda
carteiras_tratadas as (
    select
        *,
        case
            -- formato de CPF (XXX.XXX.XXX-XX) -> invalido, descarta
            when card_limpo_4 ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$' then null

            -- so numero (ignorando espacos internos) -> remove espaco e zero a esquerda
            when replace(card_limpo_4, ' ', '') ~ '^\d+$' then
                case
                    when ltrim(replace(card_limpo_4, ' ', ''), '0') = '' then '0'
                    else ltrim(replace(card_limpo_4, ' ', ''), '0')
                end

            -- tem caractere nao numerico nao tratado -> mantem para revisao manual
            else card_limpo_4
        end as dependent_card_number_tratado
    from card_passo4
),

-- Passo 3: dedup por carteira tratada + paciente beneficiario (preserva historico de troca de carteira)
numerado as (
    select
        *,
        row_number() over (
            partition by dependent_card_number_tratado, beneficiary_patient_id
            order by delivery_date desc
        ) as rn
    from carteiras_tratadas
    where dependent_card_number_tratado is not null
),

mais_recente as (
    select *
    from numerado
    where rn = 1
),

final as (
    select
        -- chave
        coverage_id                                                         as id_carteira_saude,

        -- pacientes envolvidos
        subscriber_patient_id                                               as id_paciente_titular,
        beneficiary_patient_id                                              as id_paciente_beneficiario,

        -- plano e operadora
        payor_name                                                          as nome_operadora,
        plan_name                                                           as nome_plano,

        -- carteirinhas (original + tratada lado a lado)
        dependent_card_number                                               as numero_carteira_dependente,
        dependent_card_number_tratado                                       as numero_carteira_dependente_tratado,
        subscriber_card_number                                              as numero_carteira_titular,

        -- status traduzido
        case status
            when 'active'           then 'Ativo'
            when 'cancelled'        then 'Cancelado'
            when 'draft'            then 'Rascunho'
            when 'entered-in-error' then 'Erro de registro'
            else status
        end                                                                  as status,

        -- vigência
        period_start                                                        as data_inicio_vigencia,
        period_end                                                          as data_fim_vigencia

    from mais_recente
)

select * from final
