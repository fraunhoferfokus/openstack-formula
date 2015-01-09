{%- from 'openstack/defaults.jinja' import openstack_defaults with context %}
{%- from 'neutron/map.jinja' import neutron with context %}
include:
    - neutron.neutron_config
    - neutron.ml2_config
    - neutron.controller.database
    - neutron.controller.keystone

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

neutron-dhcp-agent:
    service.running:
        - require:
            - pkg: neutron-server
            - file: neutron.conf
            - file: dhcp_agent.ini
            # dhcp-agent messes with OVS
            # so we need this one, too:
            - file: ml2_conf.ini
        - watch:
            - file: neutron.conf
            - file: dhcp_agent.ini
            - file: ml2_conf.ini

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
            - file: neutron.conf
            - file: metadata_agent.ini

metadata_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir}}/metadata_agent.ini
        - user: root
        - group: neutron
        - mode: 640
        - source: salt://neutron/files/metadata_agent.ini
        - template: jinja
        - require:
            - pkg: neutron-server
