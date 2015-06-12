# -*- coding: utf-8 -*-
'''
Managing subnets in OpenStack Neutron
======================================
'''
# Import python libs
import logging
import pprint
#import yaml

# Import salt libs and exceptions
#import salt.utils
#import salt.utils.templates
from salt.exceptions import SaltInvocationError

log = logging.getLogger(__name__)

def _update_subnet(subnet_id, subnet_params):
    '''
    Private function to compare an existing subnet's attributes to
    those requested by the state.
    '''
    log.debug("subnet_params passed to _update_subnet():\n" +\
        str(subnet_params))
    subnet = __salt__['neutron.subnet_show'](subnet_id=subnet_id)
    # neutron.subnet_show() returns
    # False on any caught error:
    if not subnet:
        return (False, 'subnet not found')
    to_update = {}

    allocation_pools = subnet_params.get('allocation_pools')
    if isinstance(allocation_pools, str):
        pools = []
        for pool in allocation_pools.split(','):
            (start, end) = pool.split('-')
            pools += [{'start': start, 'end': end}]
        subnet_params['allocation_pools'] = pools

    for key, value in subnet_params.items():
        if key == 'new_name':
            if subnet['name'] != value:
                to_update['name'] = subnet_params['new_name']
            else:
                continue
        elif key == 'tenant': 
            tenant_id = __salt__['keystone.tenant_get'](name=value)
            if subnet['tenant_id'] != tenant_id:
                to_update['tenant'] = value
        elif subnet[key] != value and subnet[key] != str(value):
            to_update[key] = value
    re_create = False
    needs_re_creation = ['cidr', 'network_id', 'tenant_id',
            'allocation_pools', 'ip_version']
    for key in needs_re_creation:
        if to_update.has_key(key):
            re_create = True
            break
    if re_create:
        __salt__['neutron.subnet_delete'](subnet_id)
        for key, value in to_update.items():
            subnet[key] = value
        name = subnet.pop('name')
        cidr = subnet.pop('cidr')
        network_id = subnet.pop('network_id')
        subnet.pop('id')
        log.debug('parameters passed to neutron.subnet_create: \n' + \
            'name = {0}, cidr = {1}, network_id = {2} and \n'.format(
                name, cidr, network_id) + \
            'those additional parameters: \n{0}'.format(str(subnet)))
        __salt__['neutron.subnet_create'](name, cidr, network_id, **subnet)
        return (True, to_update)
    else:
        __salt__['neutron.subnet_update'](subnet_id=subnet_id, **to_update)
        return(True, to_update)

def managed(name, cidr, network, allocation_pools=None,
            gateway_ip=None, ip_version=None, subnet_id=None,
            enable_dhcp=None, tenant=None, router=None):
    '''
    ### TODO:
    an existing subnet with given CIDR, network_id,
    tenant_id won't get its name changed!
    ###

    Required parameters:
    - name
    - CIDR
    - network: the Neutron-network this subnet is part of

    Optional parameters:
    - allocation_pools
    - gateway_ip
    - ip_version (4 xor 6)
    - subnet_id
    - enable_dhcp (bool)
    - tenant

    For details see neutron.subnet_create.
    '''
    ret = {'name': name,
        'changes': {},
        'result': True,
        'comment': ''}

    list_filters = {'name': name}
    # Only filter
    if not network:
        raise SaltInvocationError('Can\'t continue without arg "network"')
    if subnet_id is not None:
        list_filters['subnet_id'] = subnet_id
    if tenant is not None:
        list_filters['tenant'] = tenant
    subnet_list = __salt__['neutron.subnet_list'](**list_filters)
    log.debug('filtering for "{0}" we got "{1}"'.format(
        list_filters, subnet_list))
    if len(subnet_list) == 0:
        # retry, maybe only the name doesn't match
        list_filters.pop('name')
        subnet_list = __salt__['neutron.subnet_list'](**list_filters)
        log.debug('filtering for "{0}" we got "{1}"'.format(
            list_filters, subnet_list))
    # cidr, network attributes and a subnet's id are read-only, 'name'
    # can be changed. Thus we ignore subnets with wrong cidr, network_id
    # for now.
    for subnet in subnet_list:
        if subnet.get('cidr') != cidr or \
            subnet.get('network_id') != \
                __salt__['neutron.network_show'](name=network)['id']:
            subnet_list.remove(subnet)
    # If tenant_id is specified we only get subnets from this
    # tenant anyway, no need to remove them.
    subnet_params = list_filters.copy()
    #
    if allocation_pools is not None:
        subnet_params['allocation_pools'] = allocation_pools
    if gateway_ip is not None:
        subnet_params['gateway_ip'] = gateway_ip
    if ip_version is not None:
        subnet_params['ip_version'] = ip_version
    if enable_dhcp is not None:
        subnet_params['enable_dhcp'] = enable_dhcp
    if name is not None:
        subnet_params['new_name'] = name
    #
    if len(subnet_list) == 1:
        subnet = subnet_list[0]
        updated_subnet = _update_subnet(
                subnet['id'],
                subnet_params)
        (ret['result'], ret['changes']) = updated_subnet
        if ret['result'] and len(ret['changes'].keys()) == 0:
            ret['comment'] = 'Subnet "{0}" already exists.'.format(name)
        elif ret['result']:
            if ret['changes'].has_key('name'):
                identifier = name
                ret['comment'] = 'Updated subnet "{0}"\n({1}).'.format(
                    name, identifier)
            else:
                identifier = subnet['id']
                ret['comment'] = 'Updated subnet "{0}".'.format(identifier)
        else:
            ret['comment'] = 'Failed to update subnet "{0}".'.format(name)
    elif len(subnet_list) == 0:
        log.debug('No matching subnet found, creating a new one ' + \
            '(name = {0}, cidr = {1}, network = {2}, {0})'.format(
                name, cidr, network, subnet_params))
        if subnet_params.has_key('new_name'):
            subnet_params.pop('new_name')
        #cidr = subnet_params.pop('cidr')
        network_id = __salt__['neutron.network_show'](name=network)['id']
        subnet = __salt__['neutron.subnet_create'](
                name, cidr, network_id, **subnet_params)
        if not subnet:
            ret['result'] = False
            ret['comment'] = 'Failed to create subnet "{0}".'.format(name)
        else:
            ret['changes'] = subnet
            ret['comment'] = 'Created new subnet "{0}"'.format(name)
    else:
        ppr = pprint.PrettyPrinter(indent=4)
        for subnet in subnet_list:
            if subnet.get('name') == name:
                subnet_list.remove(subnet)
        ret['comment'] = 'Other subnets with specified parameters ' + \
                            'already exist:\n{0}'.format(
                                ppr.pformat(subnet_list))
        ret['result'] = False
    if ret['result'] and router is not None:
        added_iface = __salt__['neutron.router_add_interface'](
            router=router, subnet=subnet['name'])
        ret['comment'] += '\nAdded router "{0}" ({1}) to subnet.'.format(
            router, added_iface['id'])
        ret['changes']['router'] = router
    return ret

