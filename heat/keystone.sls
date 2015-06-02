{% from 'openstack/defaults.jinja' import openstack_defaults %}
{% from 'heat/defaults.jinja' import heat_defaults %}
heat keystone password in pillar:
    test.check_pillar:
        - string: heat:keystone_authtoken:admin_password

heat-user in Keystone:
  keystone.user_present:
    - name: heat
    - email: {{ salt['pillar.get'](
                    'openstack.service_email',
                    'heat@' + salt['pillar.get'](
                        'openstack:service_domain', 
                        openstack_defaults.service_domain)
                ) }}
    - password: {{ salt ['pillar.get'](
        'heat:keystone_authtoken:admin_password') }}
    - tenant: service
    - roles:
       service:
          - admin
    - require: 
        - test: heat keystone password in pillar
    - failhard: True

heat service in Keystone:
  keystone.service_present:
    - name: heat
    - service_type: orchestration
    - description: OpenStack Orchestration
    - require:
        - keystone: heat-user in Keystone

heat endpoint in Keystone:
  keystone.endpoint_present:
    - name: heat
{% for url_type in ['publicurl', 'internalurl', 'adminurl'] %}
    - {{ url_type }}: {{
        "http://{0}:{1}/v1/%(tenant_id)s".format( 
            salt['pillar.get'](
                'heat:api_host',
                    salt['pillar.get'](
                        'openstack:controller:address_ext',
                        '127.0.0.1')
            ),
            salt['pillar.get'](
                'heat:api_port',
                salt['pillar.get'](
                    'openstack:heat:api_port', 
                    heat_defaults.api_port)
            )
        ) }}
{% endfor %}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: heat service in Keystone

heat-cfn service in Keystone:
  keystone.service_present:
    - name: heat-cfn
    - service_type: cloudformation
    - description: Cloudformation
    - require:
        - keystone: heat-user in Keystone

heat-cfn endpoint in Keystone:
  keystone.endpoint_present:
    - name: heat-cfn
{% for url_type in ['publicurl', 'internalurl', 'adminurl'] %}
    - {{ url_type }}: {{
        "http://{0}:{1}/v1".format( 
            salt['pillar.get'](
                'heat:api_host',
                    salt['pillar.get'](
                        'openstack:controller:address_ext',
                        '127.0.0.1')
            ),
            salt['pillar.get'](
                'heat:cfn_port',
                salt['pillar.get'](
                    'openstack:heat:cfn_port', 
                    heat_defaults.cfn_port)
            )
        ) }}
{% endfor %}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: heat-cfn service in Keystone
