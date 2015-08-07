{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get('neutron:tenant',
                openstack_defaults.keystone.admin_tenant_name) %}
{# TODO: Doesn't the state accept tenant _names_ by now?? #}
{% set admin_tenant_id = salt['keystone.tenant_list']()[tenant_name]['id'] %}

{# TODO: add support for multiple external networks - but not now #}

{%- for subnet, details in get('neutron:subnets').items() %}
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
{% endfor %}
