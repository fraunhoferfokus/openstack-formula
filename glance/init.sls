{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'glance/map.jinja' import glance with context %}
glance-packages:
    pkg.installed:
        - names: 
            - glance
            - python-mysqldb

glance-api:
    service.running:
        - watch:
            - file: {{ glance.api_conf_file }}
            - file: {{ glance.api_paste_ini }}
        - require: 
            - file: {{ glance.api_conf_file }}
            - file: {{ glance.api_paste_ini }}

include:
    - glance.config
