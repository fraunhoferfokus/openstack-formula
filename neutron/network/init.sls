{% from 'neutron/map.jinja' import neutron with context %}
neutron-network-packages:
    pkg.installed:
        - names: {{ neutron.network_packages }}
