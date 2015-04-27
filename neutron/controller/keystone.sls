{%- from 'openstack/defaults.jinja' import openstack_defaults -%}
{%- from 'neutron/defaults.jinja' import neutron_defaults -%}
neutron-user in Keystone:
  keystone.user_present:
{%- set admin_user = salt['pillar.get'](
                    'neutron:keystone_authtoken:admin_user', 
                    'neutron') %}
    - name: {{ admin_user }}
    - email: {{ salt['pillar.get'](
                    'openstack.service_email',
                    'neutron@' + salt['pillar.get'](
                        'openstack:service_domain',
                        openstack_defaults.service_domain)
                ) }}
{%- if salt['pillar.get']('neutron.user', 'neutron') == admin_user %}
    - password: '{{ salt['pillar.get']('neutron.password') }}'
{%- else %}
    - password: '{{ salt ['pillar.get'](
        'neutron:common:keystone_authtoken:admin_password',
        neutron_defaults.keystone_password) }}'
{%- endif %}
    - tenant: {{ salt['pillar.get']('openstack:keystone:tenant_name',
        'service') }}
    - roles:
        service:
          - admin

neutron-service in Keystone:
  keystone.service_present:
    - name: neutron
    - service_type: network
    - description: OpenStack Networking Service

neutron-endpoint in Keystone:
  keystone.endpoint_present:
    - name: neutron
    - publicurl: {{
        "http://{0}:{1}".format(
            salt['pillar.get'](
                'neutron:common:DEFAULT:bind_host',
                salt['pillar.get']('openstack:controller:address_ext',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'neutron:server:DEFAULT:bind_port',
                salt['pillar.get'](
                    'openstack:neutron:api_port', '9696')
            )
        ) }}
    - internalurl: {{
        "http://{0}:{1}".format(
            salt['pillar.get'](
                'neutron:common:DEFAULT:bind_host',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'neutron:server:DEFAULT:bind_port',
                salt['pillar.get'](
                    'openstack:neutron:api_port', '9696')
            )
        ) }}
    - adminurl: {{
        "http://{0}:{1}".format(
            salt['pillar.get'](
                'neutron:common:DEFAULT:bind_host',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'neutron:server:DEFAULT:bind_port',
                salt['pillar.get'](
                    'openstack:neutron:api_port', '9696')
            )
        ) }}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: neutron-service in Keystone

