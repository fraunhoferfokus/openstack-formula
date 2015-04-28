{% from 'nova/map.jinja' import nova with context %}
nova passwords in pillar:
    test.check_pillar:
        - failhard: True
        - string:
            - nova:database:password
{# The keystone credentials for Nova could be set unser those keys: #}
{% if not (salt['pillar.get']('keystone.user', False) == 'nova' and
        salt['pillar.get']('keystone.password', False)) %}
            - nova:keystone_authtoken:admin_password
{% endif %}

{{ nova.nova_conf_file }}:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja
      - failhard: True
      - require:
        - test: nova passwords in pillar
{% if 'openstack-controller' in salt['pillar.get']('roles') %}
        - pkg: nova-controller-packages
{%- endif %}
{% if 'openstack-compute' in salt['pillar.get']('roles') %}
        - pkg: nova-compute
{%- endif %}
