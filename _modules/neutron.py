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
# Import salt libs
from salt.exceptions import SaltInvocationError

# Import third party libs
HAS_NEUTRON = False
try:
    from neutronclient.v2_0 import client # as neutron_client
    from neutronclient.neutron.v2_0 import agent
    import neutronclient.common.exceptions as neutron_exceptions
    HAS_NEUTRON = True
    import pprint
    import logging
    logging.basicConfig(level=logging.DEBUG)
    log = logging.getLogger(__name__)
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

def _auth(profile=None, **connection_args):
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

def network_create(name, admin_state_up = True, shared = False, 
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
    neutron = _auth()
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

def network_delete(network_id):
    '''
    Delete network of given ID.
    '''
    neutron = _auth()
    neutron.format = 'json'
    # TODO: Always returns None?
    return neutron.delete_network(network_id)

def network_list(name = None, admin_state_up = None,
        network_id = None, shared = None, status = None,
        tenant_id = None):
    '''
    List networks.

    Optional parameters to filter by:
    - name
    - admin_state_up (bool)
    - network_id
    - shared (bool, might be silently dropped on Icehouse)
    - status (like "ACTIVE")
    - tenant_id
    '''
    neutron = _auth()
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
    if tenant_id:
        kwargs['tenant_id'] = tenant_id
    return neutron.list_networks(**kwargs)['networks']

def network_show(network_id):
    '''
    Show details for network with given ID.

    ## TODO ##
    Implement "salt '*' network_show name=foo-network
    '''
    neutron = _auth()
    neutron.format = 'json'
    try:
        response = neutron.show_network(network_id)
    except neutron_exceptions.NetworkNotFoundClient:
        return False    
    return response['network']

def network_update(name = None, network_id = None, new_name = None,
        admin_state_up = None, shared = None, tenant_id = None, 
        physical_network = None, network_type = None, 
        segmentation_id = None):
    '''
    Update an existing network with given parameters.

    If there's more than one network with given name
    and tenant_id you have to specify the network_id.

    You can't change a network's ID and Neutron will refuse
    to update some other settings as well - or just ignore
    this part of your request.
    '''
    if name is None and network_id is None:
        raise SaltInvocationError, 'You have to specify'\
            'at least one of "name" or "network_id".'
    pp = pprint.PrettyPrinter(indent=4)
    net_filters = {}
    if network_id is not None:
        net_filters['network_id'] = network_id
    elif name is not None:
        net_filters['name'] = name
    if tenant_id is not None:
        net_filters['tenant_id'] = tenant_id
    log.debug('options for network_list():\n{0}'.format(
        pp.pformat(net_filters)))
    net_list = network_list(**net_filters)
    if len(net_list) > 1:
        raise SaltInvocationError, 'More than one network with those '\
            'options found:\n{}'.format(pp.pformat(net_filters))
    elif len(net_list) == 0:
        raise SaltInvocationError, 'No network with those '\
            'options found:\n{}'.format(pp.pformat(net_filters))
    else:
        param_list = {}
        if new_name is not None:
            param_list['name'] = new_name
        if network_id is None:
            network_id = net_list[0]['id']
        if admin_state_up is not None:
            param_list['shared'] = shared 
        if tenant_id is not None:
            param_list['tenant_id'] = tenant_id
        if physical_network is not None:
            param_list['provider:physical_network'] = physical_network
        if network_type is not None:
            param_list['provider:network_type'] = network_type
        if segmentation_id is not None:
            param_list['provider:segmentation_id'] = segmentation_id
        neutron = _auth()
        neutron.format = 'json'
        return neutron.update_network(network_id, {'network': param_list})

def subnet_list(name = None, subnet_id = None, cidr = None, network_id = None,
    allocation_pools = None, gateway_ip = None, ip_version = None, 
    enable_dhcp = None):
    '''
    List subnets.

    Optional parameters to filter by:
    - name (only works for non-empty names!)
    - subnet_id (works)
    - cidr (works)
    - network_id (seems to work)
    - allocation_pools (not implemented by Neutron API?)
    - gateway_ip (works)
    - ip_version (seems to work)
    - enable_dhcp (ignored by Neutron API)
    '''
    neutron = _auth()
    neutron.format = 'json'
    kwargs = {}
    if name is not None:
        kwargs['name'] = name
    if subnet_id is not None:
        kwargs['id'] = subnet_id
    if cidr is not None:
        kwargs['cidr'] = cidr
    if network_id:
        kwargs['network_id'] = network_id
    if allocation_pools:
        kwargs['allocation_pools'] = allocation_pools
    if gateway_ip:
        kwargs['gateway_ip'] = gateway_ip
    if ip_version:
        kwargs['ip_version'] = ip_version
    if enable_dhcp:
        kwargs['enable_dhcp'] = enable_dhcp
    log.debug("kwargs for list_subnets: " + str(kwargs))
    return neutron.list_subnets(**kwargs)['subnets']

def subnet_create(network_id, cidr, name = None, tenant_id = None,
            allocation_pools = None, gateway_ip = None, ip_version = '4',
            subnet_id = None, enable_dhcp = None): 
    '''
    Create a subnet with given parameters.
    "network_id" and "cidr" are required. The API also requires "ip_version"
    which this function sets to 4 by default.
    
    Optional arguments are:
    - tenant_id
    - allocation_pools (either a comma separated string with <start>-<end> 
      tuples like "192.168.17.3-192.168.17.30,192.168.17.34-192.168.17.60"
      or a YAML list of dictionaries with "start" and "end" keys. 
      # TODO #
      The later one should be changed to a YAML list with elements like 
      "192.168.17.3-192.168.17.30".)
    - gateway_ip
    - ip_version (4 or 6)
    - subnet_id
    - enable_dhcp (bool)

    CLI example::

        salt controller neutron.create_subnet \\
          e5e85c75-c95a-4cc1-abce-cd719e7ec753 192.168.2.0/24 \\
          allocation_pools=192.168.2.20-192.168.2.30
    '''
    neutron = _auth()
    neutron.format = 'json'
    kwargs = { 'network_id': network_id , 'cidr': cidr}
    if tenant_id is not None:
        kwargs['tenant_id'] = tenant_id
    if isinstance(name, str):
        kwargs['name'] = name
    if isinstance(allocation_pools, str):
        pools = []
        for pool in allocation_pools.split(','):
            (start, end) = pool.split('-')
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

def subnet_delete(subnet_id):
    '''
    Delete subnet of given ID.
    '''
    neutron = _auth()
    neutron.format = 'json'
    # TODO: Always returns None?
    return neutron.delete_subnet(subnet_id)

def subnet_show(subnet_id):
    '''
    Show details for given subnet.
    '''
    neutron = _auth()
    neutron.format = 'json'
    try:
        response = neutron.show_subnet(subnet_id)
    except neutron_exceptions.NeutronClientException:
        return False    
    return response['subnet']
