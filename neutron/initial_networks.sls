{% from 'neutron/defaults.jinja' import neutron_defaults with context -%}
{% from 'neutron/map.jinja' import neutron with context -%}
{% from 'openstack/defaults.jinja' import openstack_defaults with context -%}
{% set get = salt['pillar.get'] -%}
{% set tenant_name = get('neutron:tenant',
                openstack_defaults.keystone.admin_tenant_name) %}

{% for network, details in get('neutron:networks').items() %}
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

