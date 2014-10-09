{%- from 'openstack/defaults.jinja' import openstack_defaults with context %}
{%- from 'neutron/map.jinja' import neutron with context %}
neutron-server-packages:
    pkg.installed:
        - names: {{ neutron.server_packages }}

neutron.conf:
    file.managed:
        - name: {{ neutron.neutron_conf_file }}
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/neutron.conf
        - template: jinja
