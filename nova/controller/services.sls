{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'nova/map.jinja' import nova with context %}
nova-api:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}

nova-cert:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}

nova-conductor:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}

nova-consoleauth:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}

nova-novncproxy:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}

nova-scheduler:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}

nova-spiceproxy:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
        - require:
            - file: {{ nova.nova_conf_file }}
