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

{#- TODO:   Turn this into a jinja-macro that will be
            used here and in neutron.neutron_config #}
{%- set tenant_name = salt['pillar.get'](
    'nova:DEFAULT:neutron_admin_tenant_name',
        salt['pillar.get'](
            'neutron:common:keystone_authtoken:admin_tenant_name',
            salt['pillar.get']('openstack:keystone:admin_tenant_name',
                openstack_defaults.keystone.admin_tenant_name)
        )
    ) %}
{%- set mine_data =  salt['mine.get'](
    'I@roles:openstack-controller and S@{0}'.format(
            salt['pillar.get']('openstack:controller:address_int')),
    'keystone.tenant_list', 'compound') %}

neutron_admin_tenant_id in salt-mine:
    test.configurable_test_state:
        - failhard: True
        - changes: False
{%- if mine_data|length > 0 %}
    {%- set controller_id, tenants = mine_data.items()[0] %}
    {%- set tenant_id = tenants[tenant_name]['id'] %}
        - result: True
        - comment: |
            Found UUID "{{ tenant_id }}"
            for tenant "{{ tenant_name }}"
{%- else %}
    {%- set tenant_id = False %}
        - result: False
        - comment: |
            Can't find UUID for tenant "{{ tenant_name }}".
            Try running this command on your master:
                sudo salt -C 'I@roles:openstack-controller' \
                mine.send keystone.tenant_list
{%- endif %}
{#- End of not-yet-a-macro #}

{{ nova.nova_conf_file }}:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja
      - failhard: True
      - context:
            tenant_name: {{ tenant_name }}
            tenant_id: {{ tenant_id }}
      - require:
        - test: neutron_admin_tenant_id in salt-mine
        - test: nova passwords in pillar
{% if 'openstack-controller' in salt['pillar.get']('roles') %}
        - pkg: nova-controller-packages
{%- endif %}
{% if 'openstack-compute' in salt['pillar.get']('roles') %}
        - pkg: nova-compute
{%- endif %}
