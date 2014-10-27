{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'glance/map.jinja' import glance with context %}
glance-api:
    service.running:
        - watch:
            - file: {{ glance.api_conf_file }}
            - file: {{ glance.api_paste_ini }}
        - require: 
            - file: {{ glance.api_conf_file }}
            - file: {{ glance.api_paste_ini }}

glance-registry:
    service.running:
        - watch:
            - file: {{ glance.registry_conf_file }}
            - file: {{ glance.registry_paste_ini }}
        - require: 
            - file: {{ glance.registry_conf_file }}
            - file: {{ glance.registry_paste_ini }}

