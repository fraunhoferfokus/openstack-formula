{% from 'neutron/map.jinja' import neutron with context %}
neutron-compute-packages:
    pkg.installed:
        - names: {{ neutron.compute_packages }}
