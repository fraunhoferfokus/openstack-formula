random_subnet:
    neutron_subnet.managed:
        - cidr: 192.168.1.0/24
        - network_id: {{ salt['neutron.network_list'](
                            'random_network')[0]['id'] }}
        - allocation_pools: 192.168.1.30-192.168.1.51
        - gateway_ip: 192.168.1.200
        - ip_version: 4
        - enable_dhcp: True
