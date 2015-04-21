{% from 'openstack/defaults.jinja' import openstack_defaults %}
{% from 'cinder/defaults.jinja' import cinder_defaults %}
cinder-user in Keystone:
  keystone.user_present:
    - name: cinder
    - email: {{ salt['pillar.get'](
                    'openstack.service_email',
                    'cinder@' + salt['pillar.get'](
                        'openstack:service_domain', 
                        openstack_defaults.service_domain)
                ) }}
    - password: {{ salt ['pillar.get'](
        'cinder:keystone_authtoken:admin_password') }}
    - tenant: service
    - roles:
       service:
          - admin

cinder v1 service in Keystone:
  keystone.service_present:
    - name: cinder
    - service_type: volume
    - description: OpenStack Block Storage v1
    - require:
        - keystone: cinder-user in Keystone

cinder v1 endpoint in Keystone:
  keystone.endpoint_present:
    - name: cinder
    - publicurl: {{ 
        "http://{0}:{1}/v1/%(tenant_id)s".format( 
            salt['pillar.get'](
                'cinder:api_host',
                    salt['pillar.get'](
                        'openstack:controller:address_ext',
                        '127.0.0.1')
            ),
            salt['pillar.get'](
                'cinder:api_port',
                salt['pillar.get'](
                    'openstack:cinder:api_port', 
                    cinder_defaults.api_port)
            )
        ) }}
    - internalurl: {{ 
        "http://{0}:{1}/v1/%(tenant_id)s".format( 
            salt['pillar.get'](
                'cinder:api_host',
                salt['pillar.get'](
                    'openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'cinder:common:api_port',
                salt['pillar.get'](
                    'openstack:cinder:api_port', 
                    cinder_defaults.api_port)
            )
        ) }}
    - adminurl: {{ 
        "http://{0}:{1}/v1/%(tenant_id)s".format( 
            salt['pillar.get'](
                'cinder:api_host',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'cinder:api_port',
                salt['pillar.get'](
                    'openstack:cinder:api_port', 
                    cinder_defaults.api_port)
            )
        ) }}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: cinder v1 service in Keystone

cinder v2 service in Keystone:
  keystone.service_present:
    - name: cinderv2
    - service_type: volumev2
    - description: OpenStack Block Storage v2
    - require:
        - keystone: cinder-user in Keystone

cinder v2 endpoint in Keystone:
  keystone.endpoint_present:
    - name: cinderv2
    - publicurl: {{ 
        "http://{0}:{1}/v2/%(tenant_id)s".format( 
            salt['pillar.get'](
                'cinder:api_host',
                    salt['pillar.get']('openstack:controller:address_ext',
                        '127.0.0.1')
                ),
            salt['pillar.get'](
                'cinder:api_port',
                salt['pillar.get'](
                    'openstack:cinder:api_port', 
                    cinder_defaults.api_port)
            )
        ) }}
    - internalurl: {{ 
        "http://{0}:{1}/v2/%(tenant_id)s".format( 
            salt['pillar.get'](
                'cinder:api_host',
                salt['pillar.get'](
                    'openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'cinder:common:api_port',
                salt['pillar.get'](
                    'openstack:cinder:api_port', 
                    cinder_defaults.api_port)
            )
        ) }}
    - adminurl: {{ 
        "http://{0}:{1}/v2/%(tenant_id)s".format( 
            salt['pillar.get'](
                'cinder:api_host',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'cinder:api_port',
                salt['pillar.get'](
                    'openstack:cinder:api_port', 
                    cinder_defaults.api_port)
            )
        ) }}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: cinder v2 service in Keystone
