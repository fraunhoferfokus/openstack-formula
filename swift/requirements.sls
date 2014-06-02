{% if salt['pillar.get']('swift:dev_requirements', False) %}
{% set requirements = salt['pillar.raw'](key='swift')['dev_requirements'] %}
  {% for state, value in requirements.items() %}
{{state}}: {{ value }}
  {% endfor %}
{% endif %}
