{% from 'neutron/map.jinja' import neutron with context %}
neutron-network-packages:
    pkg.installed:
        - names: {{ neutron.network_packages }}

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

l3_agent.ini:
    file.managed:
        - name: {{ neutron.l3_agent_ini }}
        - source: salt://neutron/files/l3_agent.ini
        - template: jinja
        - user: root
        - group: neutron
        - mode: 640

# see http://docs.openstack.org/icehouse/install-guide/install/apt/content/neutron-ml2-network-node.html
ml2_conf.ini:
    file.managed:
        #- name: {#{ neutron.plugins_ml2_conf_ini }#}
        - name: {{ neutron.conf_dir }}/plugins/ml2/ml2_conf.ini
        - source: salt://neutron/files/ml2_conf.ini
        - template: jinja
        - user: root
        - group: neutron
        - mode: 640

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
