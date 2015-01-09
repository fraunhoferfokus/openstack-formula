{% from 'neutron/map.jinja' import neutron with context %}
include:
    - neutron.neutron_config
    - neutron.ml2_config
    - neutron.openvswitch_agent

neutron-compute-packages:
    pkg.installed:
        - names: {{ neutron.compute_packages }}
        - require:
            - file: neutron.conf
