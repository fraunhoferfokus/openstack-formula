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

        ## TODO: test s/t like this ##
    
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

    Optional parameters:
    - admin_state_up (default: True)
    - shared (default: False) 
    - tenant_id (only by admin users) 
    - physical_network 
    - network_type (like flat, vlan, vxlan, and gre)
    - segmentation_id (VLAN ID, GRE Key)

    OpenStack Networking API reference:
    http://developer.openstack.org/api-ref-networking-v2.html#networks
    '''
    # todo: refuse to create multiple networks with the same name
    # in the same tenant
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
    # Neither filtering by segmentation_id nor 
    # by provider:segmentation_id works.
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

def network_show(network_id = None, name = None):
    '''
    Show details for network with given ID or name.

    CLI examples:
        salt controller network_show 6327c548-8d28-4205-a171-99b350aad078
        salt controller network_show name=foo-network
    '''
    neutron = _auth()
    neutron.format = 'json'
    response = False
    if network_id is not None:
        try:
            response = neutron.show_network(network_id)['network']
        except neutron_exceptions.NetworkNotFoundClient:
            # response stays False
            pass
    elif name is not None:
        net_list = network_list(name = name)
        if len(net_list) == 1:
            response = net_list[0]
    else:
        raise (SaltInvocationError, 
                'network_id or name has to be specified')
    return response

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

    OpenStack Networking API reference:
    http://developer.openstack.org/api-ref-networking-v2.html#networks
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
    tenant_id = None, gateway_ip = None, ip_version = None):
    '''
    List subnets.

    Optional parameters to filter by:
    - name (only works for non-empty names!)
    - subnet_id
    - cidr 
    - network_id 
    - gateway_ip 
    - ip_version 
    '''
    # Those potential parameters don't work:
    #  - allocation_pools (not implemented by Neutron API?)
    #  - enable_dhcp (ignored by Neutron API)
    # See https://bugs.launchpad.net/neutron/+bug/1418635
    # You can't list subnets by ID so we get it via subnet_show.
    # Neutron would fall apart if you had to subnets with the 
    # same ID anyway.

    neutron = _auth()
    neutron.format = 'json'
    kwargs = {}
    if subnet_id is not None:
        return([subnet_show(subnet_id)])
    else:
        if name is not None:
            kwargs['name'] = name
        if cidr is not None:
            kwargs['cidr'] = cidr
        if network_id:
            kwargs['network_id'] = network_id
        if gateway_ip:
            kwargs['gateway_ip'] = gateway_ip
        if ip_version:
            kwargs['ip_version'] = ip_version
        if tenant_id:
            kwargs['tenant_id'] = tenant_id
        log.debug("kwargs for list_subnets: " + str(kwargs))
        return neutron.list_subnets(**kwargs)['subnets']

def router_add_interface(name, router_id, admin_state_up = True,
        subnet_id = None, port_id = None):
    '''
    Add interface ("port") to an existing router. 

    Required parameters:
    - name
    - router_id

    Optional parameters:
    - admin_state_up (defaults to True)
    - subnet_id
    - port_id
    '''
    neutron = _auth()
    neutron.format = 'json'
    kwargs = {
        'name': name,
        'admin_state_up': admin_state_up,
        }
    if subnet_id is not None:
        kwargs['subnet_id'] = subnet_id
    if port_id is not None:
        kwargs['port_id'] = port_id
    log.debug(dir(neutron.add_interface_router))
    return neutron.add_interface_router(router_id, {'port': kwargs})

def router_create(name, admin_state_up = True, network_id = None,
        tenant_id = None, subnet_id = None, port_id = None):
    '''
    Create a new router.

    Required parameters: 
    - name

    Optional parameters:
    - admin_state_up (defaults to True)
    - tenant_id
    - subnet_id*
    - port_id*

    *) Specifying those results in an additional call of
       router_add_interface after creating the actual 
       router
    '''
    # Parameter 'network_id' has to be wrapped like this:
    #   "external_gateway_info":{
    #         "network_id":"8ca37218-28ff-41cb-9b10-039601ea7e6b"
    #               }
    neutron = _auth()
    neutron.format = 'json'
    kwargs = {
        'name': name,
        'admin_state_up': admin_state_up,
        }
    add_iface = False
    iface_args = {}
    if network_id is not None:
        kwargs['external_gateway_info'] = { 
            'network_id': network_id }
    if tenant_id is not None:
        kwargs['tenant_id'] = tenant_id
    if subnet_id is not None:
        add_iface = True
        iface_args['subnet_id'] = subnet_id 
    if port_id is not None:
        add_iface = True
        iface_args['port_id'] = port_id

    if not add_iface:
        return neutron.create_router({'router': kwargs})
    else:
        try:
            router = neutron.create_router({'router': kwargs})['router']
        except neutron_exceptions.NeutronClientException, err_msg:
            return (False, 
                'Failed to create router "{0}":\n'.format(name) + str(err_msg))
                
        iface = router_add_interface('interface for router {0}'.format(name), 
            router['id'], **iface_args)['port']
        if not iface:
            return(
                False, 
                'Failed to add port to router "{0}"\n'.format(name) +\
                'after router was created with id {0}'.format(router['id'])
                )
        return { 'router': router, 'port': iface}
            
def subnet_create(name, cidr, network_id, tenant_id = None,
            allocation_pools = None, gateway_ip = None, ip_version = '4',
            enable_dhcp = None, dns_nameservers = None,
            host_routes = None): 
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
    - enable_dhcp (bool)
    - dns_nameservers*
    - host_routes*

    *) Not documented in OpenStack Networking API reference,
       see https://bugs.launchpad.net/neutron/+bug/1418635

    OpenStack Networking API reference:
    http://developer.openstack.org/api-ref-networking-v2.html#subnets

    CLI example::

        salt controller neutron.create_subnet test-subnet \\
          e5e85c75-c95a-4cc1-abce-cd719e7ec753 192.168.2.0/24 \\
          allocation_pools=192.168.2.20-192.168.2.30
    '''
    # todo: refuse to create multiple subnets with the same name
    # in the same network
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
    if dns_nameservers is not None:
        kwargs['dns_nameservers'] = dns_nameservers
    if host_routes is not None:
        kwargs['host_routes'] = host_routes
    if gateway_ip is not None:
        kwargs['gateway_ip'] = gateway_ip
    if ip_version not in ['4', '6', 4, 6]:
        raise ValueError, "ip_version has to be 4 or 6"
    elif ip_version is not None:
        kwargs['ip_version'] = ip_version
    if enable_dhcp is not None:
        kwargs['enable_dhcp'] = enable_dhcp
    try:
        return neutron.create_subnet({'subnet': kwargs})['subnet']
    except ValueError:
        return False

def subnet_delete(subnet_id):
    '''
    Delete subnet of given ID.
    '''
    neutron = _auth()
    neutron.format = 'json'
    resp = neutron.delete_subnet(subnet_id)
    if resp is None:
        return True
    elif isinstance(resp, bool) and not resp:
        return False

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

def subnet_update(name = None, subnet_id = None, new_name = None,
        gateway_ip = None, enable_dhcp = None):
    '''
    Update an existing subnet with given parameters.
    
    If there's more than one subnet with given name
    you have to specify the subnet_id.
    
    Parameters for identifying the correct subnet:
    - name
    - subnet_id
    - network_id
    - tenant_id

    You have to provide at least 'name' OR 'subnet_id'.

    Updatable attributes:
    - new_name
    - gateway_ip
    - enable_dhcp (bool)

    Neutron may refuse to update some settings or just ignore
    this part of your request even if the API reference states
    something else (see 
    https://bugs.launchpad.net/neutron/+bug/1418635)
    
    OpenStack Networking API reference:
    http://developer.openstack.org/api-ref-networking-v2.html#subnets
    '''
    # Only file bugs for missing parameters if they don't cause those:
    # - Cannot update read-only attribute allocation_pools
    # - Cannot update read-only attribute network_id
    # - Cannot update read-only attribute tenant_id
    # - Cannot update read-only attribute id 
    #
    if name is None and subnet_id is None:
        raise SaltInvocationError, 'You have to specify'\
            'at least one of "name" or "subnet_id".'
    neutron = _auth()
    neutron.format = 'json'
    pp = pprint.PrettyPrinter(indent=4)
    subnet_filters = {}
    if subnet_id is not None:
        subnet_filters['subnet_id'] = subnet_id
    elif name is not None:
        subnet_filters['name'] = name
    log.debug('options for subnet_list():\n{0}'.format(
        pp.pformat(subnet_filters)))
    sub_list = subnet_list(**subnet_filters)
    if len(sub_list) > 1:
        raise SaltInvocationError, 'More than one subnet with those '\
            'options found:\n{}'.format(pp.pformat(subnet_filters))
    elif len(sub_list) == 0:
        raise SaltInvocationError, 'No subnet with those '\
            'options found:\n{}'.format(pp.pformat(subnet_filters))
    param_list = {}
    if new_name is not None:
        param_list['name'] = new_name
    if subnet_id is None:
        subnet_id = sub_list[0]['id']
    #if network_id is not None:
    #    param_list['network_id'] = network_id
    #if tenant_id is not None:
    #    param_list['tenant_id'] = tenant_id
    #if allocation_pools is not None:
    #    param_list['allocation_pools'] = allocation_pools
    if gateway_ip is not None:
        param_list['gateway_ip'] = gateway_ip
    #if new_id is not None:
    #    param_list['id'] = new_id
    if enable_dhcp is not None:
        param_list['enable_dhcp'] = enable_dhcp
    resp = neutron.update_subnet(subnet_id, {'subnet': param_list})
    return resp['subnet']

