with source as (
    select * from {{ source('prontlife', 'customepisodeofcare') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as episode_of_care_id,

        -- paciente
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        data -> 'subject' ->> 'display'                                     as patient_name,

        -- programa
        data -> 'healthProgram' ->> 'display'                               as health_program_name,
        data -> 'healthProgram' ->> 'reference'                             as health_program_reference,

        -- categoria (fallback para semanas antigas)
        coalesce(
            data -> 'healthProgram' ->> 'display',
            data -> 'category' ->> 'display'
        )                                                                   as category_display,
        coalesce(
            data -> 'healthProgram' ->> 'code',
            data -> 'category' ->> 'code'
        )                                                                   as category_code,

        -- gestor (array com role/member — semanas novas)
        coalesce(
            replace(
                data -> 'careManager' -> 0 -> 'member' ->> 'reference',
                'Practitioner/', ''
            ),
            replace(
                data -> 'careManager' -> 0 ->> 'reference',
                'Practitioner/', ''
            )
        )                                                                   as care_manager_id,
        coalesce(
            data -> 'careManager' -> 0 -> 'member' ->> 'display',
            data -> 'careManager' -> 0 ->> 'display'
        )                                                                   as care_manager_name,
        data -> 'careManager' -> 0 -> 'role' ->> 'code'                    as care_manager_role_code,
        data -> 'careManager' -> 0 -> 'role' ->> 'display'                 as care_manager_role,

        -- equipe de referência (array completo — desdobrar na intermediate)
        data -> 'careTeam'                                                  as care_team,

        -- organização
        replace(
            data -> 'managingOrganization' ->> 'reference', 'Organization/', ''
        )                                                                   as organization_id,

        -- status e período
        data ->> 'status'                                                   as status,
        (data -> 'period' ->> 'start')::timestamptz                        as period_start,
        (data -> 'period' ->> 'end')::timestamptz                          as period_end,

        -- inativação (formato não padrão com microsegundos)
        to_timestamp(
            data ->> 'inactivationDateTime',
            'YYYY-MM-DD HH24:MI:SS.US'
        )                                                                   as inactivation_datetime,

        -- observações
        data ->> 'note'                                                     as note,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
