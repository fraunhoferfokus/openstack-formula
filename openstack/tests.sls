{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}

include:
    - neutron.initial_networks

test-tenant:
    keystone.tenant_present:
        - description: Test-Tenant of the OpenStack-Formula
        - enabled: True

test-user:
    keystone.user_present:
        - description: Test-User of the OpenStack-Formula
        - password: FlamOoFrysVankEttAj2
        - email: test@example.com
        - tenant: test-tenant
        - enabled: True
        - roles:
            test-tenant:
                - admin
                - Member
        - require:
            - keystone: test-tenant

test-network:
    neutron_network.managed:
        - admin_state_up: True
        - tenant: test-tenant
        - require:
            - keystone: test-tenant

test-router:
    neutron_router.managed:
        - tenant: test-tenant
        - gateway_network: external network
        - enable_snat: True
        #- enable_snat: False
        - require:
            - neutron_network: external network
            - keystone: test-tenant 

test-subnet:
    neutron_subnet.managed:
        - cidr: 192.168.0.0/24
        - network: test-network
        - allocation_pools: 192.168.0.100-192.168.0.200
        - enable_dhcp: True
        - tenant: test-tenant
        - router: test-router
        - require: 
            - keystone: test-tenant
            - neutron_router: test-router
