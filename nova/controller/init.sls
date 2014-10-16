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

include:
    - nova.controller.database
    - nova.controller.services
