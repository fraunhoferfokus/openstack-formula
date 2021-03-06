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
from salt.utils.odict import OrderedDict 

# Import third party libs
HAS_NEUTRON = False
try:
    from neutronclient.v2_0 import client # as neutron_client
    #from neutronclient.neutron.v2_0 import agent
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
        '''
        TODO
        '''
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

def _id_to_tenantname(tenant_id):
    '''
    Uses keystone.tenant_get() get the tenant name to given ID.

    Workaround for https://github.com/saltstack/salt/issues/24568
    '''
    tenant_dict = \
        __salt__['keystone.tenant_get'](tenant_id)
    if len(tenant_dict) == 1:
        tenant_dict = tenant_dict[tenant_dict.keys()[0]]
    return tenant_dict['name']

def _tenantname_to_id(tenant):
    '''
    Uses keystone.tenant_get() to resolv a tenant name.

    Workaround for https://github.com/saltstack/salt/issues/24568
    '''
    tenant_dict = __salt__['keystone.tenant_get'](name=tenant)
    if tenant_dict.has_key(tenant):
        tenant_dict = tenant_dict[tenant]
    return tenant_dict['id']

def network_create(name, admin_state_up=True, shared=False,
        tenant_id=None, physical_network=None, external=None,
        network_type=None, segmentation_id=None):
    '''
    Create a network with given name.

    Optional parameters:
    - admin_state_up (default: True)
    - shared (default: False) 
    - tenant_id (only by admin users) 
    - physical_network 
    - external
    - network_type (like flat, vlan, vxlan, and gre)
    - segmentation_id (VLAN ID, GRE Key)

    OpenStack Networking API reference:
    http://developer.openstack.org/api-ref-networking-v2.html#networks
    '''
    # todo: refuse to create multiple networks with the same name
    # in the same tenant
    neutron = _auth()
    neutron.format = 'json'
    param_list = {'name': name, 
        'admin_state_up': admin_state_up,
        'shared': shared }
    if tenant_id is not None:
        param_list['tenant_id'] = tenant_id
    if physical_network is not None:
        param_list['provider:physical_network'] = physical_network
    if network_type is not None:
        param_list['provider:network_type'] = network_type
    # Kilo might turn None into "null":
    if segmentation_id is not None and segmentation_id != "null":
        param_list['provider:segmentation_id'] = segmentation_id
    if external is not None:
        param_list['router:external'] = external
    ret = neutron.create_network({'network': param_list})
    return ret

def network_delete(network_id):
    '''
    Delete network of given ID.
    '''
    neutron = _auth()
    neutron.format = 'json'
    # TODO: Always returns None? Can't get this one to 
    # return False when NetworkNotFoundClient is raised...
    #try:
    if neutron.delete_network(network_id) is None:
        return True
    #except neutron_exceptions.NetworkNotFoundClient, err_msg:
    #    return False, err_msg
    return False

def network_list(name = None, admin_state_up = None,
        network_id = None, shared = None, status = None,
        tenant_id = None, external = None):
    '''
    List networks.

    Optional parameters to filter by:
    - name
    - admin_state_up (bool)
    - network_id
    - shared (bool, might be silently dropped on Icehouse)
    - status (like "ACTIVE")
    - tenant_id
    - external (bool)
    '''
    # Neither filtering by segmentation_id nor 
    # by provider:segmentation_id works, but
    # "router:external" does!
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
    if external is not None:
        kwargs['router:external'] = external
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
        external = None, segmentation_id = None):
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
        if external is not None:
            param_list['router:external'] = external
        neutron = _auth()
        neutron.format = 'json'
        return neutron.update_network(network_id, {'network': param_list})

def port_list(network_id = None, mac_address = None):
    '''
    List ports.

    Implemented filters:
    - network_id
    - mac_address

    Details contain:
    - port_id
    - name
    - mac_address
    - fixed_ip, which consists of:
        - subnet_id
        - ip_address

    CLI example::

        salt \* neutron.port_list mac_address='fa:16:3e:50:8a:fa'
    '''
    # For details see
    # http://developer.openstack.org/api-ref-networking-v2-ext.html#listPorts
    neutron = _auth()
    neutron.format = 'json'

    retrieve_all = True
    params = {}
    if network_id:
        #retrieve_all = False
        params['network_id'] = network_id
    if mac_address:
        params['mac_address'] = mac_address
    try:
        return neutron.list_ports(retrieve_all, **params)['ports']
    except TypeError:
        return False

def port_show(port_id):
    '''
    List ports.

    No filters implemented yet.

    Details contain:
    - port_id
    - name
    - mac_address
    - fixed_ip:
        subnet_id
        ip_address
    '''
    neutron = _auth()
    neutron.format = 'json'

    try:
        return neutron.show_port(port_id)['port']
    except neutron_exceptions.PortNotFoundClient:
        return False

def subnet_list(name = None, subnet_id = None, cidr = None, 
        network_id = None, tenant = None, gateway_ip = None, 
        ip_version = None):
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
        return([subnet_show(subnet_id = subnet_id)])
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
        if tenant:
            kwargs['tenant_id'] = _tenantname_to_id(tenant)
            log.debug("kwargs for list_subnets: " + str(kwargs))
        return neutron.list_subnets(**kwargs)['subnets']

def router_add_interface(router=None, subnet=None,
        tenant=None, admin_state_up=True):
    '''
    Add interface ("port") to an existing router.

    Required parameters:
    - router
    - subnet

    Optional parameters:
    - tenant # TODO
    - admin_state_up (defaults to True)
    '''
    neutron = _auth()
    neutron.format = 'json'
    pformat = pprint.PrettyPrinter(indent=4).pformat
    if router is None:
        raise SaltInvocationError(
            'Required arg "router" not specified')
    else:
        router = router_show(name=router)
    if subnet is None:
        raise SaltInvocationError(
            'Required arg "subnet" not specified')
    kwargs = {
        'admin_state_up': admin_state_up,
        }
    if subnet is not None:
        # def router_in_subnet()?
        subnet = \
            __salt__['neutron.subnet_show'](subnet)
        kwargs['subnet_id'] = subnet['id']
        network_id = subnet['network_id']
        ports = port_list(network_id=network_id)
        log.debug('Ports for subnet "{0}" '.format(subnet['name']) + \
            'in network "{0}":\n'.format(network_id) + \
            pformat(ports))
        for port in ports:
            dev_type = 'network:router_interface'
            dev_id = port['device_id']
            if port['device_owner'] == dev_type and \
                    dev_id == router['id']:
                # result = router, exists_already=True??
                return None
    try:
        result = neutron.add_interface_router(
            router['id'], kwargs)
    except neutron_exceptions.NeutronClientException, msg:
        log.error('Calling neutron.add_interface_router(' + \
            "{0}, {1})".format(router['id'],
                kwargs) + 'caused:\n{0}'.format(msg))
        raise neutron_exceptions.NeutronClientException
    return result

def router_create(name, admin_state_up = True, tenant_id = None, 
        gateway_network = None, enable_snat = True, tenant=None):
    '''
    Create a new router.

    Required parameters: 
    - name

    Optional parameters:
    - admin_state_up (defaults to True)
    - tenant_id XOR tenant
    - gateway_network (network_id of external network)
    - enable_snat (defaults to True)
    '''
    if (tenant_id is None and tenant is None):
        raise SaltInvocationError('Neither tenant_id nor tenant are set.')
    if (tenant_id is not None and tenant is not None):
        raise SaltInvocationError('tenant_id and tenant must not be set both.')
    
    neutron = _auth()
    neutron.format = 'json'
    kwargs = {
        'name': name,
        'admin_state_up': admin_state_up,
        }
    add_iface = False
    iface_args = {}
    if gateway_network is not None:
        kwargs['external_gateway_info'] = { 
            'network_id': gateway_network,
            'enable_snat': enable_snat,
            }
    if tenant_id is not None:
        kwargs['tenant_id'] = tenant_id
    if tenant is not None:
        kwargs['tenant_id'] = _tenantname_to_id(tenant)

    return neutron.create_router({'router': kwargs})

#def router_delete(name = None, router_id = None): # ip = None?
def router_delete(router_id):
    '''
    Delete the router specified by UUID
    '''
    neutron = _auth()
    neutron.format = 'json'
    try:
        neutron.delete_router(router_id)
        log.debug('Deleted router {0}'.format(router_id))
        return True
    except neutron_exceptions.NeutronClientException, msg:
        log.debug('NeutronClientException: {0}'.format(msg))
        return False
    return None

def router_list(name = None, status = None, tenant = None,
        admin_state_up = None):
    '''
    List routers.

    Optional filter parameters:
    - name
    - status ('ACTIVE', 'DOWN', 'ERROR')
    - tenant
    '''
    # Can't filter by network_id
    neutron = _auth()
    neutron.format = 'json'
    kwargs = {}
    if name is not None:
        kwargs['name'] = name
    if status is not None:
        if status not in ['ACTIVE', 'ERROR', 'DOWN']:
            raise SaltInvocationError('status has to be one of' +
                '"ACTIVE", "ERROR" or "DOWN"')
        else:
            kwargs['status'] = status
    if tenant is not None:
        kwargs['tenant_id'] = _tenantname_to_id(tenant)
    if admin_state_up is not None:
        kwargs['admin_state_up'] = admin_state_up
    router_list = neutron.list_routers(**kwargs)
    if router_list.has_key('routers'):
        router_list = router_list['routers']
    if isinstance(router_list, type(None)) or \
            len(router_list) == 0:
        return []
    for router in router_list:
        router['tenant'] = _id_to_tenantname(router['tenant_id'])
        if router.has_key('external_gateway_info'):
            if isinstance(router['external_gateway_info'], type(None)):
                pass
            elif router['external_gateway_info'].has_key('network_id'):
                net_id = router['external_gateway_info']['network_id']
                net_name = __salt__['neutron.network_show'](net_id)['name']
                router['external_gateway_info']['network'] = net_name
    return router_list

def router_set_gateway(router_id, ext_net_id, 
        enable_snat = True):
    '''
    Set external network as gateway for fiven router.
    '''
    neutron = _auth()
    neutron.format = 'json'
    return router_update(router_id, 
        gateway_network = ext_net_id, enable_snat = enable_snat)

def router_show(name = None, router_id = None):
    '''
    Show the router specified by UUID
    '''
    # TODO: Add tenant kwarg b/c different tenants
    #   could use the same names for their routers
    neutron = _auth()
    neutron.format = 'json'
    if name is None and router_id is None:
        raise SaltInvocationError('Neither name nor router_id given!')
    elif router_id is None:
        routers = router_list(name=name)
        if len(routers) == 1:
            return routers[0]
    return neutron.show_router(router_id)

def router_update(router_id, admin_state_up = None, 
        new_name = None, gateway_network = None, 
        enable_snat = True):
    '''
    Update parameters of given router.

    Optional parameters:
    - admin_state_up
    - new_name
    - gateway_network (network_id of external network)
    - enable_snat
    '''
    # - Cannot update read-only attribute tenant_id
    # 
    #if name is None and router_id is None:
    #    raise SaltInvocationError, 'You have to specify'\
    #        'at least one of "name" or "router_id".'
    neutron = _auth()
    neutron.format = 'json'
    pp = pprint.PrettyPrinter(indent=4)
    kwargs = {}
    if admin_state_up is not None:
        kwargs['admin_state_up'] = admin_state_up
    if gateway_network is not None:
        kwargs['external_gateway_info'] = { 
            'network_id': gateway_network,
            'enable_snat': enable_snat,
            }
        if enable_snat is "null":
            # Workaround for Neutron-API of Kilo:
            kwargs['external_gateway_info'].pop('enable_snat')
    if new_name is not None:
        kwargs['name'] = new_name
    log.debug('options for router_update() on router {0}:\n{1}'.format(
        router_id, pp.pformat(kwargs)))
    return neutron.update_router(router_id, {'router': kwargs})

            
def subnet_create(name, cidr, network_id, tenant = None,
            allocation_pools = None, gateway_ip = None, ip_version = '4',
            enable_dhcp = None, dns_nameservers = None,
            host_routes = None): 
    '''
    Create a subnet with given parameters.
    "network_id" and "cidr" are required. The API also requires "ip_version"
    which this function sets to 4 by default.
    
    Optional arguments are:
    - tenant
    - allocation_pools:
        If neither a comma separated string with <start>-<end> tuples 
        like "192.168.17.3-192.168.17.30,192.168.17.34-192.168.17.60"
        nor a YAML list  with elements like "192.168.17.3-192.168.17.30"
        work for you try a list of dictionaries like this one:
        ``{start: 192.168.17.3, end: 192.168.17.30}``
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
    if tenant is not None:
        kwargs['tenant_id'] = _tenantname_to_id(tenant)
    if isinstance(name, str):
        kwargs['name'] = name
    log.debug('allocation_pools "{0}" is {1}.'.format(
        allocation_pools, type(allocation_pools)))
    if isinstance(allocation_pools, dict) or \
            isinstance(allocation_pools, OrderedDict):
        pass
    elif isinstance(allocation_pools, (str,unicode)):
        allocation_pools = allocation_pools.split(',')
    if allocation_pools is not None:
        kwargs['allocation_pools'] = []
        for pool in allocation_pools:
            if isinstance(pool, dict):
                if 'start' in pool and 'end' in pool:
                    continue
                else:
                    raise(ValueError, '{0} doesn\'t '.format(str(pool)) +\
                        'contain required keys "start" and "end".')
                # Maybe Juno-Neutron doesn't like unicode??
                if isinstance(pool['start'], unicode):
                    pool['start'] = str(pool['start'])
                if isinstance(pool['end'], unicode):
                    pool['end'] = str(pool['end'])
            (start, end) = pool.split('-')
            kwargs['allocation_pools'] += [
                {'start': start,
                'end': end}]
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
    except ValueError, msg:
        log.debug('ValueError: {0}'.format(msg))
        return False
    except neutron_exceptions.NeutronClientException, msg:
        log.error('NeutronClientException: {0}'.format(msg))
        return False

def subnet_delete(name = None, subnet_id = None):
    '''
    Delete subnet of given ID.
    '''
    neutron = _auth()
    neutron.format = 'json'
    if name is not None and subnet_id is not None:
        raise SaltInvocationError(
            'Specify name XOR subnet_id')
    elif subnet_id is None:
        subnet_id = subnet_show(name = name)
    try:
        resp = neutron.delete_subnet(subnet_id)
    except neutron_exceptions.NeutronClientException, msg:
        log.error('NeutronClientException in subnet_delete(' + \
            'name = {0}, subnet_id = {1}): {2}'.format(
                name, subnet_id, msg))
        return False
    if resp is None:
        return True
    elif isinstance(resp, bool) and not resp:
        return False

def subnet_show(name = None, subnet_id = None, 
        cidr = None, tenant = None):
    '''
    Show details for given subnet.

        salt '*' neutron.subnet_show test-subnet
        salt '*' neutron.subnet_show \\
            subnet_id=ee699962-38ef-4f94-bbd0-2def3f0e20ab
    '''
    pp = pprint.PrettyPrinter(indent=4)
    neutron = _auth()
    neutron.format = 'json'
    if subnet_id is not None:
        try:
            response = neutron.show_subnet(subnet_id)['subnet']
        except neutron_exceptions.NeutronClientException, msg:
            log.debug('NeutronClientException: {0}'.format(msg))
            return False    
    elif name is not None or cidr is not None or tenant is not None:
        kwargs = {}
        if name is not None:
            kwargs['name'] = name
        if cidr is not None:
            kwargs['cidr'] = cidr
        if tenant is not None:
            kwargs['tenant'] = tenant
        sub_list = subnet_list(**kwargs)
        if len(sub_list) == 0:
            return False
        elif len(sub_list) > 1:
            collision_list = []
            for sub in sub_list:
                col_sub = {}
                for key in ['name', 'id', 'cidr']:
                    col_sub[key] = sub[key]
                col_sub['tenant'] = _id_to_tenant(sub['tenant_id'])
                collision_list += [col_sub]
            raise SaltInvocationError("Result for given\nkwargs " + \
                "({0}) ambiguous:\n{1}".format(kwargs.keys(), 
                    pp.pformat(collision_list)))
        else:
            response = sub_list[0]
    response['network_name'] = \
        __salt__['neutron.network_show'](
            response['network_id'])['name']
    response['tenant_name'] = _id_to_tenantname(response['tenant_id'])
    return response

def subnet_update(name = None, subnet_id = None, new_name = None,
        gateway_ip = None, enable_dhcp = None, tenant = None):
    '''
    Update an existing subnet with given parameters.
    
    If there's more than one subnet with given name
    you have to specify the subnet_id.
    
    Parameters for identifying the correct subnet:
    - name
    - subnet_id
    - network_id
    - tenant

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
        raise SaltInvocationError('You have to specify' +\
            'at least one of "name" or "subnet_id".')
    neutron = _auth()
    neutron.format = 'json'
    pp = pprint.PrettyPrinter(indent=4)
    subnet_filters = {}
    if subnet_id is not None:
        subnet_filters['subnet_id'] = subnet_id
    elif name is not None:
        subnet_filters['name'] = name
    if tenant is not None:
        subnet_filters['tenant'] = tenant
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

