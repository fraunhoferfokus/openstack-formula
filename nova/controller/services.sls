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
            - service: nova-scheduler
            - mysql_grants: nova-grants

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
            - service: nova-api
            - service: nova-scheduler
        - require:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
            - service: nova-api
            - service: nova-scheduler

nova-novncproxy:
    service.running:
        - watch:
            - file: {{ nova.nova_conf_file }}
            - cmd: nova-manage db sync
        - require:
            - file: {{ nova.nova_conf_file }}
            - service: nova-consoleauth

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
            - service: nova-consoleauth
