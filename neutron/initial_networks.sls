{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get('neutron:tenant',
                openstack_defaults.keystone.admin_tenant_name) %}

# Layer 2 Networks:
{% for network, details in get('neutron:networks', {}).items() %}
{{ network }}:
    neutron_network.managed:
        - admin_state_up: {{ details.admin_state_up }}
        - shared: {{ details.shared }}
    {% if 'tenant' in details %}
        - tenant: {{ details.tenant }}
    {% else %}
        - tenant: {{ tenant_name }}
    {% endif %}
    {% if 'physical_network' in details %}
        - physical_network: {{ details.physical_network }}
    {% endif %}
        - network_type: {{ details.network_type }}
    {% if 'external' in details %}
        - external: {{ details.external }}
    {% endif %}
{% endfor %}

# Layer 3 Routers:
{%- for router, details in get('neutron:routers', {}).items() %}
{{ router }}:
    neutron_router.managed:
    {%- if 'tenant' in details %}
        - tenant: {{ details.tenant }}
    {%- else %}
        - tenant: {{ tenant_name }}
    {%- endif %}
    {%- for key in ['gateway_network', 'enable_snat'] %}
        {%- if key in details %}
        - {{ key }}: {{ details[key] }}
        {%- endif %}
    {%- endfor %}
    {%- if 'gateway_network' in details and
        details['gateway_network'] in get('neutron:networks') %}
        - require:
            - neutron_network: {{ details['gateway_network'] }}
        {%- for sub_name, sub_details in
                get('neutron:subnets', {}).items() %}
            {%- if details['gateway_network'] == sub_details['network'] %}
            - neutron_subnet: {{ sub_name }}
            {%- endif %}
        {%- endfor %}
    {%- endif %}
{%- endfor %}

# ...and now Layer-3-Subnets:
{%- for subnet, details in get('neutron:subnets', {}).items() %}
{{ subnet }}:
    neutron_subnet.managed:
    {%- for key in ['cidr', 'network', 'enable_dhcp', 'tenant'] %}
        {%- if details.has_key(key) %}
        - {{ key }}: {{ details[key] }}
        {%- endif %}
    {%- endfor %}
        - allocation_pools:
    {%- if details.allocation_pools is string %}
        {% set allocation_pools = details.allocation_pools.split(',') %}
    {%- else %}
        {% set allocation_pools = details.allocation_pools %}
    {% endif %}
    {%- for pool in details.allocation_pools %}
            - {{ pool }}
    {%- endfor %}
    {%- if details['network'] in get('neutron:networks') %}
        - require:
            - neutron_network: {{ details['network'] }}
    {%- endif %}
{% endfor %}
