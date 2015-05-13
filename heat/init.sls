{% from 'heat/map.jinja' import heat with context %}

include: 
    - heat.database

heat-packages:
    pkg.installed:
        - names: {{ heat.packages }}

heat.conf:
    file.managed:
        - name: {{ heat['heat_conf_file'] }}
        - source: salt://heat/files/heat.conf
        - template: jinja
        - user: heat
        - group: heat
        - mode: 640
        - require:
            - pkg: heat-packages

{% for service in heat['services'] %}
{{service}}:
    service.running:
        - require:
            - pkg: heat-packages
            - file: heat.conf
        - watch:
            - pkg: heat-packages
            - file: heat.conf
{% endfor %}
