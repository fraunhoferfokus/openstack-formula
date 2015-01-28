# -*- coding: utf-8 -*-
'''
Managing subnets in OpenStack Neutron
======================================
'''
# Import python libs
import logging
import pprint
#import yaml

# Import salt libs
import salt.utils
import salt.utils.templates

log = logging.getLogger(__name__)

def _update_subnet(subnet_id, subnet_params):
    '''
    Private function to compare an existing subnet's attributes to
    those requested by the state.
    '''
    log.debug("subnet_params passed to _update_subnet():\n" + str(subnet_params))
    subnet = __salt__['neutron.subnet_show'](subnet_id)
    to_update = {}
    for key, value in subnet_params.items():
        if subnet[key] != value:
            to_update[key] = value
    re_create = False
    needs_re_creation = ['cidr', 'network_id', 'tenant_id', 
            'allocation_pools', 'ip_version', 'subnet_id' ]
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
        __salt__['neutron.subnet_create'](name, cidr, network_id, **subnet)
        return (True, to_update)
    else:
        __salt__['neutron.subnet_update'](subnet_id = subnet_id, **to_update)
        return(True, to_update)

def managed(name, cidr, network_id, allocation_pools = None, 
            gateway_ip = None, ip_version = '4', subnet_id = None, 
            enable_dhcp = None, tenant_id = None):
    '''
    Required parameters:
    - name
    - CIDR
    - network_id of the Neutron-network this subnet is part of

    Optional parameters:
    - allocation_pools 
    - gateway_ip
    - ip_version (4 xor 6)
    - subnet_id
    - enable_dhcp (bool)
    - tenant_id
    
    For details see neutron.subnet_create.
    '''
    ret = { 'name': name,
        'changes': {},
        'result': True,
        'comment': ''}
    
    list_filters = {'name': name}
    # Only filter 
    if network_id is not None:
        list_filters['network_id'] = network_id
    if subnet_id is not None:
        list_filters['subnet_id'] = subnet_id
    if tenant_id is not None:
        list_filters['tenant_id'] = tenant_id
    subnet_list = __salt__['neutron.subnet_list'](**list_filters)
    log.debug(subnet_list)
    # cidr, network_id attributes and a subnet's id are read-only, 'name'
    # can be changed. Thus we ignore subnets with wrong cidr, network_id
    # for now.
    for subnet in subnet_list:
        if subnet.get('cidr') != cidr or \
                subnet.get('network_id') != network_id:
            subnet_list.remove(subnet)
    # If tenant_id if specified we only get subnets from this
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
    # 
    if len(subnet_list) == 1:
        subnet = subnet_list[0]
        (ret['result'], ret['changes']) = _update_subnet(
                subnet['id'], 
                subnet_params)
        if ret['result'] and len(ret['changes'].keys()) == 0:
            ret['comment'] = 'Subnet {0} already exists.'.format(name)
        elif ret['result']:
            if ret['changes'].has_key('name'):
                identifier = subnet['id']
            else:
                identifier = name
            ret['comment'] = 'Updated subnet {0}.'.format(identifier)
        else:
            ret['comment'] = 'Failed to update subnet {0}.'.format(name)
    elif len(subnet_list) == 0:
        name = subnet_params.pop('name')
        #cidr = subnet_params.pop('cidr')
        network_id = subnet_params.pop('network_id')
        subnet = __salt__['neutron.subnet_create'](
                name, cidr, network_id, **subnet_params)
        if not subnet:
            ret['result'] = False
            ret['comment'] = 'Failed to create subnet "{0}".'.format(name)
        else:
            ret['changes'] = subnet
            ret['comment'] = 'Created new subnet "{0}"'.format(name)
    else:
        pp = pprint.PrettyPrinter(indent=4)
        for subnet in subnet_list:
            if subnet.get('name') == name:
                subnet_list.remove(subnet)
        ret['comment'] = 'Other subnets with specified parameters '\
                        'already exist:\n{0}'.format(pp.pformat(net_list))
        ret['result'] = False
    return ret
