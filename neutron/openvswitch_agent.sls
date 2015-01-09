neutron-plugin-openvswitch-agent:
    pkg.installed:
        - require:
            - file: ml2_conf.ini
    service.running:
        - require:
            - pkg: neutron-plugin-openvswitch-agent
            - file: ml2_conf.ini
        - watch:
            - file: ml2_conf.ini
