test_network_external:
    neutron_network.managed:
        - shared: True 
        - network_type: flat 
        - physical_network: External

test_random_network:
    neutron_network.managed

test_vlan_network:
    neutron_network.managed:
        - network_type: vlan
        - segmetation_id: 2000

test_gre_network:
    neutron_network.managed:
        - network_type: gre
        - segmentation_id: 2000
