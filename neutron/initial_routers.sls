{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get('neutron:tenant',
                openstack_defaults.keystone.admin_tenant_name) %}

router for external network:
    neutron_router.managed:
        - tenant: {{ tenant_name }}

test-router:
    neutron_router.managed:
        - tenant: test-tenant
        - gateway_network: external network
        - enable_snat: True
        #- enable_snat: False
