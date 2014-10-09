{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'nova/map.jinja' import nova with context %}
nova-controller-packages:
  pkg.installed:
    - names: {{ nova.controller_packages }}

{{ nova.nova_conf_file }}:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja
      - require:
        - pkg: nova-controller-packages

{% if salt['pillar.get']('nova:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/nova/nova.sqlite:
    file:
      - absent
{% endif %}

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
