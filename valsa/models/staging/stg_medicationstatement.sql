with source as (
    select * from {{ source('prontlife', 'medicationstatement') }}
),

renamed as (
    select
        -- chaves
        id                                                                  as medication_statement_id,

        -- referências
        replace(data -> 'subject' ->> 'reference', 'Patient/', '')         as patient_id,
        replace(data -> 'context' ->> 'reference', 'Encounter/', '')       as encounter_id,

        -- information source (pode ser Practitioner ou Patient)
        split_part(data -> 'informationSource' ->> 'reference', '/', 2)    as information_source_id,
        split_part(data -> 'informationSource' ->> 'reference', '/', 1)    as information_source_type,
        data -> 'informationSource' ->> 'display'                           as information_source_name,

        -- medicamento
        replace(
            data -> 'medicationReference' ->> 'reference', 'Medication/', ''
        )                                                                   as medication_id,
        data -> 'medicationReference' ->> 'display'                         as medication_name,

        -- categoria (objeto direto, não array)
        data -> 'category' -> 'coding' -> 0 ->> 'code'                     as category_code,

        -- uso contínuo
        (
            select (ext ->> 'valueBoolean')::boolean
            from jsonb_array_elements(data -> 'extension') as ext
            where ext ->> 'url' like '%medicationstatement-continuo%'
            limit 1
        )                                                                   as is_continuous,

        -- posologia (primeira instrução — campo chama dosage, não dosageInstruction)
        data -> 'dosage' -> 0 ->> 'text'                                    as dosage_text,
        data -> 'dosage' -> 0 -> 'route' -> 'coding' -> 0 ->> 'display'    as route,
        (
            data -> 'dosage' -> 0 -> 'doseAndRate' -> 0
                -> 'doseQuantity' ->> 'value'
        )::numeric                                                          as dose_value,
        data -> 'dosage' -> 0 -> 'doseAndRate' -> 0
            -> 'doseQuantity' ->> 'unit'                                    as dose_unit,

        -- status e observação
        data ->> 'status'                                                   as status,
        data -> 'note' -> 0 ->> 'text'                                     as note,

        -- data do registro
        (data ->> 'dateAsserted')::timestamptz                             as date_asserted,

        -- metadados
        delivery_date,
        ingested_at

    from source
)

select * from renamed
