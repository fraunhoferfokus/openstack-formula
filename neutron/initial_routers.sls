{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get('neutron:tenant',
                openstack_defaults.keystone.admin_tenant_name) %}

{%- for router, details in get('neutron:routers').items() %}
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
{%- endfor %}
