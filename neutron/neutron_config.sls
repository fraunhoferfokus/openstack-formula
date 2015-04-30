{% from 'openstack/defaults.jinja' import openstack_defaults %}
{% from 'neutron/map.jinja' import neutron with context %}
{{ neutron.conf_dir }}:
    file.directory:
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 750
{% else %}
        - mode: 755
{% endif %}
        - makedirs: True

neutron passwords in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('nova:verbose', False) or
                        salt['pillar.get']('nova:debug:', False) }}
        - string:
{%- if not salt['pillar.get']('neutron.password', False) %}
            - neutron:keystone_authtoken:admin_password
{% else %}
            - neutron.password
{%- endif %}
{#- Only the neutron-server needs the db credentials #}
{%- if 'openstack-controller' in pillar.get('roles', []) %}
            - neutron:database:password
{%- endif %}
            - openstack:rabbitmq:password 

nova-credentials for Neutron in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('nova:verbose', False) or
                        salt['pillar.get']('nova:debug:', False) }}
        - string: 
{% if not salt['pillar.get'](
    'nova:keystone_authtoken:admin_password', False) %}
            - neutron:nova_admin_password
{% elif salt['pillar.get']('keystone.user') == 'nova' and
    salt['pillar.get']('keystone.password', False) is string %}
            - keystone.password
{% else %}
            - nova:keystone_authtoken:admin_password
{% endif %}
        
{#- TODO:   Turn this into a jinja-macro that will be
            used here and in neutron.neutron_config #}
{%- set tenant_name = salt['pillar.get'](
                'openstack:keystone:admin_tenant_name',
                openstack_defaults.keystone.admin_tenant_name
    ) %}
{%- set mine_data =  salt['mine.get'](
    'I@roles:openstack-controller and S@{0}'.format(
            salt['pillar.get']('openstack:controller:address_int')),
    'keystone.tenant_list', 'compound') %}

nova_admin_tenant_id in salt-mine:
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
neutron.conf:
    file.managed:
        - name: {{ neutron.conf_dir}}/neutron.conf
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 640
{% else %}
        - mode: 644
{% endif %}
        - source: salt://neutron/files/neutron.conf
        - template: jinja
        - context:
            tenant_name: {{ tenant_name }}
            tenant_id: {{ tenant_id }}
        - failhard: True
        - require:
            - test: neutron passwords in pillar
        #   - pkg: neutron-server
