{%- from 'openstack/defaults.jinja' import openstack_defaults with context %}
{%- from 'neutron/map.jinja' import neutron with context %}
neutron-server-packages:
    pkg.installed:
        - names: {{ neutron.server_packages }}

neutron.conf:
    file.managed:
        - name: {{ neutron.conf_dir}}/neutron.conf
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/neutron.conf
        - template: jinja

ml2_conf.ini:
    file.managed:
        - name: {{ neutron.conf_dir }}/plugins/ml2/ml2_conf.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/ml2_conf.ini
        - template: jinja

dhcp_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir}}/dhcp_agent.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/dhcp_agent.ini
        - template: jinja

metadata_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir}}/metadata_agent.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/metadata_agent.ini
        - template: jinja
