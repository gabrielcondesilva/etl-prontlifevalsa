{% macro unescape_html(column) %}
    replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
        {{ column }},
        '&aacute;', 'á'),
        '&eacute;', 'é'),
        '&iacute;', 'í'),
        '&oacute;', 'ó'),
        '&uacute;', 'ú'),
        '&atilde;', 'ã'),
        '&otilde;', 'õ'),
        '&acirc;', 'â'),
        '&ecirc;', 'ê'),
        '&ocirc;', 'ô'),
        '&ccedil;', 'ç'),
        '&Aacute;', 'Á'),
        '&Eacute;', 'É'),
        '&amp;', '&'
    )
{% endmacro %}
