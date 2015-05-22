{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get(
            'openstack:keystone:admin_tenant_name',
                openstack_defaults.keystone.admin_tenant_name)
    -%}
{% set admin_tenant_id = salt['keystone.tenant_list']()[tenant_name]['id'] %}

external subnet:
    neutron_subnet.managed:
        - cidr: 192.168.122.0/24
        - network_id: {{ 
            salt['neutron.network_show'](name='external network')['id'] }}
        - allocation_pools: 192.168.122.100-192.168.122.200
        - enable_dhcp: True
        - tenant_id: {{ admin_tenant_id }}

test-subnet:
    neutron_subnet.managed:
        - cidr: 192.168.0.0/24
        - network_id: {{
            salt['neutron.network_show'](name='test-network')['id'] }}
        - allocation_pools: 192.168.0.100-192.168.0.200
        - enable_dhcp: True
        - tenant_id: {#
            salt['keystone.tenant_list']()['test-tenant']['id'] #}
