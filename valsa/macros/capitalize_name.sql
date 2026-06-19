{% macro capitalize_name(column) %}
    (
        select string_agg(
            case
                when lower(word) in ('de', 'da', 'do', 'dos', 'das', 'e')
                then lower(word)
                else initcap(word)
            end,
            ' '
        )
        from unnest(string_to_array(lower(trim({{ column }})), ' ')) as word
        where word != ''
    )
{% endmacro %}
