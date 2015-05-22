{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get(
        'nova:DEFAULT:neutron_admin_tenant_name',
        get('neutron:common:keystone_authtoken:admin_tenant_name',
            get('openstack:keystone:admin_tenant_name',
                openstack_defaults.keystone.admin_tenant_name)
        )
    ) -%}
{% set tenant_id = salt['keystone.tenant_list']()[tenant_name]['id'] -%}

router for external network:
    neutron_router.managed:
        - tenant_id: {{ tenant_id }}

test-router :
    neutron_router.managed:
        - tenant_id: {{
            salt['keystone.tenant_list']()['test-tenant']['id'] }}
        - gateway_network: {{ 
            salt['neutron.network_list'](external=True)[0]['id'] }}
        - enable_snat: True
        #- enable_snat: False
