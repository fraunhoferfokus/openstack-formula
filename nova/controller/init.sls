{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'nova/defaults.jinja' import nova_defaults with context %}
{% from 'nova/map.jinja' import nova with context %}

include:
    - nova.controller.database
    - nova.controller.services

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

nova-controller-packages:
  pkg.installed:
    - names: {{ nova.controller_packages }}

{{ nova.nova_conf_file }}:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja
      - failhard: True
      - require:
        - pkg: nova-controller-packages
        - test: nova passwords in pillar

nova-user in Keystone:
  keystone.user_present:
{% set admin_user = salt['pillar.get'](
                'nova:keystone_authtoken:admin_user', 'nova') %}
    - name: {{ admin_user }}
    - email: {{ salt['pillar.get'](
                    'openstack.service_email',
                    admin_user + salt['pillar.get'](
                        'openstack:service_domain', 
                        openstack_defaults.service_domain)
                ) }}
{# This one isn't allowed to default or the if will break! #}
{% if salt['pillar.get']('keystone.user') == admin_user %}
    - password: {{ salt['pillar.get']('keystone.password',
                        nova_defaults.keystone_password) }}
{% else %}
    - password: {{ salt ['pillar.get'](
                        'nova:keystone_authtoken:admin_password',
                        nova_defaults.keystone_password) }}
{% endif %}
    - tenant: service
    - roles:
        service:
          - admin
    - failhard: True
    - require:
        - cmd: nova-manage db sync
        - test: nova passwords in pillar

nova-service in Keystone:
  keystone.service_present:
    - name: nova
    - service_type: compute
    - description: OpenStack Compute Service
    - require: 
        - keystone: nova-user in Keystone

nova-endpoint in Keystone:
  keystone.endpoint_present:
    - name: nova
    - publicurl: {{ 
        "http://{0}:{1}/v2/$(tenant_id)s".format( 
            salt['pillar.get'](
                'nova:common:DEFAULT:my_ip',
                salt['pillar.get']('openstack:controller:address_ext',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'openstack:nova:compute_port', '8774')
            ) }}
    - internalurl: {{ 
        "http://{0}:{1}/v2/$(tenant_id)s".format( 
            salt['pillar.get'](
                'nova:common:DEFAULT:my_ip',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'openstack:nova:compute_port', '8774')
            ) }}
    - adminurl: {{ 
        "http://{0}:{1}/v2/$(tenant_id)s".format( 
            salt['pillar.get'](
                'nova:common:DEFAULT:my_ip',
                salt['pillar.get']('openstack:controller:address_int',
                    '127.0.0.1')
            ),
            salt['pillar.get'](
                'openstack:nova:compute_port', '8774')
            ) }}
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack.region',
                        openstack_defaults.region_name)
                 ) }}
    - require:
        - keystone: nova-service in Keystone
