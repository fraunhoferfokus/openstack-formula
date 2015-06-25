{% from 'openstack/defaults.jinja' import openstack_defaults %}
{% from 'nova/map.jinja' import nova with context %}
nova passwords in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('nova:verbose', False) or
                        salt['pillar.get']('nova:debug:', False) }}
        - string:
            - nova:database:password
{# The keystone credentials for Nova could be set unser those keys: #}
{% if (salt['pillar.get']('keystone.user', False) == 'nova' and
        salt['pillar.get']('keystone.password', False)) %}
            - keystone.user
            - keystone.password
{% else %}
            - nova:keystone_authtoken:admin_password
{% endif %}

neutron-credentials for Nova in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('nova:verbose', False) or
                        salt['pillar.get']('nova:debug:', False) }}
        - string:
{% if salt['pillar.get'](
    'neutron:keystone_authtoken:admin_password', False) %}
            - neutron:keystone_authtoken:admin_password
{% else %}
            - nova:neutron_admin_password
{% endif %}
            - openstack:neutron:shared_secret

{{ nova.nova_conf_file }}:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja
      - failhard: True
      - context:
            tenant_name: service
            tenant_id: {{ salt['keystone.tenant_get'](name='service')['service']['id'] }}
      - require:
        - test: nova passwords in pillar
{% if 'openstack-controller' in salt['pillar.get']('roles') %}
        - pkg: nova-controller-packages
{%- endif %}
{% if 'openstack-compute' in salt['pillar.get']('roles') %}
        - pkg: nova-compute
{%- endif %}
