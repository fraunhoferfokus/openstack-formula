{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'nova/map.jinja' import nova with context %}
nova-api:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync

nova-cert:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}

nova-conductor:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync

nova-consoleauth:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync

nova-novncproxy:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}

nova-scheduler:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}

nova-spiceproxy:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}
