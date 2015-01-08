{%- from 'openstack/defaults.jinja' import openstack_defaults with context %}
{%- from 'neutron/map.jinja' import neutron with context %}
neutron-server:
    pkg.installed:
        - names: {{ neutron.controller_packages }}
    service.running:
        - require:
            - pkg: neutron-server
            - file: neutron.conf
            - file: ml2_conf.ini
            - mysql_grants: neutron-grants
            #- cmd: neutron-db-manage upgrade
        - watch: 
            - pkg: neutron-server
            - file: neutron.conf
            - file: ml2_conf.ini
            #- cmd: neutron-db-manage upgrade

neutron.conf:
    file.managed:
        - name: {{ neutron.conf_dir}}/neutron.conf
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/neutron.conf
        - template: jinja
        - require:
            - pkg: neutron-server

ml2_conf.ini:
    file.managed:
        - name: {{ neutron.conf_dir }}/plugins/ml2/ml2_conf.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/ml2_conf.ini
        - template: jinja
        - require:
            - pkg: neutron-server

neutron-l3-agent:
    service.running:
        - require:
            - pkg: neutron-server
            - file: neutron.conf
            - file: l3_agent.ini
        - watch:
            - file: l3_agent.ini

l3_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir }}/l3_agent.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/l3_agent.ini
        - template: jinja
        - require:
            - pkg: neutron-server

neutron-dhcp-agent:
    service.running:
        - require:
            - pkg: neutron-server
            - file: neutron.conf
            - file: dhcp_agent.ini
        - watch:
            - file: dhcp_agent.ini

dhcp_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir}}/dhcp_agent.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/dhcp_agent.ini
        - template: jinja
        - require:
            - pkg: neutron-server

neutron-metadata-agent:
    service.running:
        - require:
            - pkg: neutron-server
            - file: neutron.conf
            - file: metadata_agent.ini
        - watch:
            - file: metadata_agent.ini

metadata_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir}}/metadata_agent.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/metadata_agent.ini
        - template: jinja
        - require:
            - pkg: neutron-server

include:
  - neutron.controller.database
  - neutron.controller.keystone
