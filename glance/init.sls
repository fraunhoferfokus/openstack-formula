{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'glance/map.jinja' import glance with context %}

include:
    - glance.config
    - glance.database
    - glance.services

passwords for glance in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('glance:verbose', False) or
                        salt['pillar.get']('glance:debug:', False) }}
        - string:
            - glance:keystone_authtoken:admin_password
            - glance:database:password

glance-packages:
    pkg.installed:
        - names: 
            - glance
            - python-mysqldb

glance-user in Keystone:
  keystone.user_present:
    - name: glance
    - email: {{ salt['pillar.get'](
                    'openstack.service_email',
                    'glance@' + salt['pillar.get'](
                        'openstack:service_domain', 
                        openstack_defaults.service_domain)
                ) }}
    - password: {{ salt ['pillar.get'](
        'glance:keystone_authtoken:admin_password') }}
    - tenant: service
    - roles:
        service:
          - admin
    - failhard: True
    - require:
        - test: passwords for glance in pillar

glance-service in Keystone:
  keystone.service_present:
    - name: glance
    - service_type: image
    - description: OpenStack Image Service
    - require:
        - keystone: glance-user in Keystone

glance-endpoint in Keystone:
  keystone.endpoint_present:
    - name: glance
    - publicurl: {{ 
        "http://{0}:{1}/v2".format( 
            salt['pillar.get'](
                'glance:api:bind_host',
                salt['pillar.get'](
                    'glance:common:DEFAULT:bind_host',
                    salt['pillar.get']('openstack:controller:address_ext',
                        '127.0.0.1')
                )
            ),
            salt['pillar.get'](
                'glance:common:api_port',
                salt['pillar.get'](
                    'openstack:glance:api_port', '9292')
            )
        ) }}
    - internalurl: {{ 
        "http://{0}:{1}/v2".format( 
            salt['pillar.get'](
                'glance:common:DEFAULT:bind_host',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'glance:common:api_port',
                salt['pillar.get'](
                    'openstack:glance:api_port', '9292')
            )
        ) }}
    - adminurl: {{ 
        "http://{0}:{1}/v2".format( 
            salt['pillar.get'](
                'glance:common:DEFAULT:bind_host',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'glance:common:api_port',
                salt['pillar.get'](
                    'openstack:glance:api_port', '9292')
            )
        ) }}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: glance-service in Keystone
