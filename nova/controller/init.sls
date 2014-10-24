{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'nova/map.jinja' import nova with context %}
nova-controller-packages:
  pkg.installed:
    - names: {{ nova.controller_packages }}

{{ nova.nova_conf_file }}:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja
      - require:
        - pkg: nova-controller-packages

nova-user in Keystone:
  keystone.tenant_present:
    - name: nova
    - tenant: service
    - roles:
      - service:
        - admin

nova-service in Keystone:
  keystone.service_present:
    - name: nova
    - service_type: compute
    - description: OpenStack Compute Service

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
{#  #TODO:
    #- region #}
    - require:
        - keystone: nova-service in Keystone

include:
    - nova.controller.database
    - nova.controller.services
