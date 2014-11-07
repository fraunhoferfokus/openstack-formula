{%- from 'openstack/defaults.jinja' import openstack_defaults -%}
{%- from 'neutron/defaults.jinja' import neutron_defaults -%}
neutron-user in Keystone:
  keystone.user_present:
    - name: neutron
    - email: {{ salt['pillar.get'](
                    'openstack.service_email',
                    'neutron@' + salt['pillar.get'](
                        'openstack:service_domain',
                        openstack_defaults.service_domain)
                ) }}
    - password: {{ salt ['pillar.get'](
        'neutron:common:keystone_authtoken:admin_password',
        neutron_defaults.keystone_password) }}
    - tenant: service
    - roles:
      - service:
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
{#  #TODO:
    #- region #}
    - require:
        - keystone: neutron-service in Keystone

