{% macro extract_fhir_id(column, resource_type) %}
    replace({{ column }} ->> '{{ resource_type }}', '{{ resource_type }}/', '')
{% endmacro %}
