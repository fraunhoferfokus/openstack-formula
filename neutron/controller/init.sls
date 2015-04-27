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

shared secret for metadata_agent in pillar:
    test.check_pillar:
        - string:
            - openstack:neutron:shared_secret

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
            - test: shared secret for metadata_agent in pillar:
