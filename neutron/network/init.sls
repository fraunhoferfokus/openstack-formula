{% from 'neutron/map.jinja' import neutron with context %}
include:
    - neutron.neutron_config
    - neutron.ml2_config
    - neutron.openvswitch_agent

neutron-network-packages:
    pkg.installed:
        - names: {{ neutron.network_packages }}
        - require: 
            - file: neutron.conf
            - file: ml2_conf.ini

set net.ipv4.ip_forward=1 for neutron:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1

set net.ipv4.conf.all.rp_filter=0 for neutron:
    sysctl.present:
        - name: net.ipv4.conf.all.rp_filter
        - value: 0

set net.ipv4.conf.default.rp_filter=0 for neutron:
    sysctl.present:
        - name: net.ipv4.conf.default.rp_filter
        - value: 0

neutron-l3-agent:
    pkg:
        - installed
    service.running:
        - require:
            - file: neutron.conf
            - file: l3_agent.ini
        - watch:
            - file: neutron.conf
            - file: l3_agent.ini

l3_agent.ini:
    file.managed:
        - name: {{ neutron.l3_agent_ini }}
        - source: salt://neutron/files/l3_agent.ini
        - template: jinja
        - user: root
        - group: neutron
        - mode: 640

neutron-dhcp-agent:
    service.running:
        - require:
            - pkg: neutron-network-packages
            - file: neutron.conf
            - file: dhcp_agent.ini
            # dhcp-agent messes with OVS
            # so we need this one, too:
            - file: ml2_conf.ini
        - watch:
            - file: neutron.conf
            - file: dhcp_agent.ini
            - file: ml2_conf.ini

dhcp_agent.ini:
    file.managed:
        - name: {{ neutron.conf_dir}}/dhcp_agent.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/dhcp_agent.ini
        - template: jinja
        - require:
            - pkg: neutron-network-packages

