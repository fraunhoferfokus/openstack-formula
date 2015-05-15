{% from 'heat/map.jinja' import heat with context %}

include: 
    - heat.database
    - heat.keystone

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

heat log_dir:
    file.directory:
        - name: {{ heat.log_dir }}
        - user: heat
        - group: heat
        - mode: 770
        - require:
            - pkg: heat-packages

{% for service in heat['services'] %}
{{service}}:
    service.running:
        - require:
            - pkg: heat-packages
            - file: heat.conf
            - file: heat log_dir
        - watch:
            - pkg: heat-packages
            - file: heat.conf
{% endfor %}
