# -*- coding: utf-8 -*-
'''

Module for handling openstack neutron calls.

:optdepends:    - neutronclient Python adapter

:configuration: This module is not usable until the following are specified
    either in a pillar or in the minion's config file::

        ## TODO: Check which of those are needed
    
        neutron.user: neutron
        neutron.password: verybadpass
        neutron.tenant: service
        neutron.tenant_id: f80919baedab48ec8931f200c65a50df
        neutron.auth_url: 'http://127.0.0.1:5000/v2.0/'
        neutron.endpoint: 'http://127.0.0.1:9696'

    If configuration for multiple openstack accounts is required, they can be
    set up as different configuration profiles:
    For example::

        ## TODO ##
    
        openstack1:
          keystone.user: admin
          keystone.password: verybadpass
          keystone.tenant: admin
          keystone.tenant_id: f80919baedab48ec8931f200c65a50df
          keystone.auth_url: 'http://127.0.0.1:5000/v2.0/'

        openstack2:
          keystone.user: admin
          keystone.password: verybadpass
          keystone.tenant: admin
          keystone.tenant_id: f80919baedab48ec8931f200c65a50df
          keystone.auth_url: 'http://127.0.0.2:5000/v2.0/'

    With this configuration in place, any of the neutron functions can make use
    of a configuration profile by declaring it explicitly.
    For example::

        salt '*' neutron.network_list profile=openstack1
'''

# Import third party libs
HAS_NEUTRON = False
try:
    from neutronclient.v2_0 import client # as neutron_client
    from neutronclient.neutron.v2_0 import agent
    import neutronclient.common.exceptions
    HAS_NEUTRON = True
    import salt.modules.keystone.auth as auth
    import logging
    logging.basicConfig(level=logging.DEBUG)
except ImportError:
    pass


def __virtual__():
    '''
    Only load this module if keystone
    is installed on this minion.
    '''
    if HAS_NEUTRON:
        return 'neutron'
    return False

__opts__ = {}

def auth(profile=None, **connection_args):
    '''
    Set up neutron credentials

    Only intended to be used within neutron-enabled modules
    '''

    if profile:
        prefix = profile + ":neutron."
    else:
        prefix = "neutron."

    # look in connection_args first, then default to config file
    def get(key, default=None):
        return connection_args.get('connection_' + key,
            __salt__['config.get'](prefix + key, default))

    user = get('user', 'admin')
    password = get('password', 'ADMIN')
    tenant = get('tenant', 'admin')
    tenant_id = get('tenant_id')
    auth_url = get('auth_url', 'http://127.0.0.1:35357/v2.0/')
    insecure = get('insecure', False)
    token = get('token')
    region = get('region')
    endpoint = get('endpoint', 'http://127.0.0.1:9696/v2.0')

    if token:
        kwargs = {'token': token,
                  'username': user,
                  'endpoint_url': endpoint,
                  'auth_url': auth_url,
                  'region_name': region,
                  'tenant_name': tenant}
    else:
        kwargs = {'username': user,
                  'password': password,
                  'tenant_id': tenant_id,
                  'auth_url': auth_url,
                  'region_name': region,
                  'tenant_name': tenant}
        # 'insecure' keyword not supported by all v2.0 keystone clients
        #   this ensures it's only passed in when defined
        if insecure:
            kwargs['insecure'] = True

    return client.Client(**kwargs)

def create_network(name, admin_state_up = True, shared = False, 
        tenant_id = None, physical_network = None, 
        network_type = None, segmentation_id = None):
    '''
    Create a network with given name.

    Additional valid parameters:
    - admin_state_up (default: True)
    - shared (default: False) 
    - tenant_id (only by admin users) 
    - physical_network 
    - network_type (like flat, vlan, vxlan, and gre)
    - segmentation_id (VLAN ID, GRE Key)
    '''
    neutron = auth()
    neutron.format = 'json'
    network = {'name': name, 
        'admin_state_up': admin_state_up,
        'shared': shared }
    if tenant_id is not None:
        network['tenant_id'] = tenant_id
    if physical_network is not None:
        network['provider:physical_network'] = physical_network
    if network_type is not None:
        network['provider:network_type'] = network_type
    if segmentation_id is not None:
        network['provider:segmentation_id'] = segmentation_id
    #ret = {}
    ret = neutron.create_network({'network':network})
    return ret

def delete_network(network_id):
    # TODO: docstring
    neutron = auth()
    neutron.format = 'json'
    # TODO: Always returns None?
    return neutron.delete_network(network_id)

def list_networks(name = None, admin_state_up = None,
        network_id = None, shared = None, status = None,
        subnets = None, tenant_id = None):
    # TODO: docstring
    neutron = auth()
    neutron.format = 'json'
    kwargs = {}
    if name is not None:
        kwargs['name'] = name
    if admin_state_up is not None:
        kwargs['admin_state_up'] = admin_state_up
    if network_id:
        kwargs['id'] = network_id
    if shared:
        kwargs['shared'] = shared
    if status:
        kwargs['status'] = status
    if subnets:
        kwargs['subnets'] = subnets
    if tenant_id:
        kwargs['tenant_id'] = tenant_id
    return neutron.list_networks(**kwargs)

def list_subnets():
    neutron = auth()
    neutron.format = 'json'
    return neutron.list_subnets()

def create_subnet(network_id, cidr, name = None, tenant_id = None,
        allocation_pools = None, gateway_ip = None, ip_version = '4',
        subnet_id = None, enable_dhcp = None): 
    '''
    Create a subnet with given parameters.
    "network_id" and "cidr" are required. The API also requires "ip_version"
    which this function sets to 4 by default.
    
    Optional arguments are:
    - tenant_id
    - allocation_pools (format??)
    - gateway_ip
    - ip_version (4 or 6)
    - subnet_id
    - enable_dhcp

    CLI example::

        salt controller neutron.create_subnet \\
          e5e85c75-c95a-4cc1-abce-cd719e7ec753 192.168.2.0/24 \\
          'allocation_pools=[{"start": "192.168.2.20", "end": "192.168.2.30"}]'
    '''
    neutron = auth()
    neutron.format = 'json'
    kwargs = { 'network_id': network_id , 'cidr': cidr}
    if tenant_id is not None:
        kwargs['tenant_id'] = tenant_id
    if isinstance(allocation_pools,str):
        pools = []
        for pool in allocation_pools.split(','):
            (start, end) = pool.split(':')
            pools += [{'start': start, 'end': end}]
        kwargs['allocation_pools'] = pools
    elif allocation_pools is not None:
        kwargs['allocation_pools'] = allocation_pools
    if gateway_ip is not None:
        kwargs['gateway_ip'] = gateway_ip
    if ip_version not in ['4', '6', 4, 6]:
        raise ValueError, "ip_version has to be 4 or 6"
    elif ip_version is not None:
        kwargs['ip_version'] = ip_version
    if subnet_id is not None:
        kwargs['id'] = subnet_id
    if enable_dhcp is not None:
        kwargs['enable_dhcp'] = enable_dhcp
    return neutron.create_subnet({'subnet': kwargs})

def delete_subnet(network_id):
    # TODO: docstring
    neutron = auth()
    neutron.format = 'json'
    # TODO: Always returns None?
    return neutron.delete_subnet(network_id)
