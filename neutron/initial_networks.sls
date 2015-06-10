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

external network:
    neutron_network.managed:
        - admin_state_up: True
        - shared: True
        - tenant: {{ tenant_name }}
        - physical_network: External
        - network_type: flat
        - external: True

