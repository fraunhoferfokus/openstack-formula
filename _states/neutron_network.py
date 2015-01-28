# -*- coding: utf-8 -*-
'''
Managing networks in OpenStack Neutron
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

def managed(name, admin_state_up = None, network_id = None,
        shared = None, tenant_id = None, physical_network = None,
        network_type = None, segmentation_id = None):
    # TODO: docstring
    ret = { 'name': name,
        'changes': {},
        'result': True,
        'comment': ''}
    
    list_filters = {'name': name}
    if admin_state_up is not None:
        list_filters['admin_state_up'] = admin_state_up
    if network_id is not None:
        list_filters['network_id'] = network_id
    if tenant_id is not None:
        list_filters['tenant_id'] = tenant_id
    net_list = __salt__['neutron.network_list'](**list_filters)
    log.debug(net_list)
    net_params = list_filters.copy()
    # filtering by those didn't work for me
    if shared is not None:
        net_params['shared'] = shared
    if physical_network is not None:
        net_params['physical_network'] = physical_network
    if network_type is not None:
        net_params['network_type'] = network_type
    if segmentation_id is not None:
        net_params['segmentation_id'] = segmentation_id
    for net in net_list:
        for key, value in net_params.items():
            if net.get(key) != net_params[key]:
                if net in net_list:
                    net_list.remove(net)
                else: 
                    continue
    if len(net_list) == 1:
        ret['comment'] = 'Network {0} already exists'.format(name)
    elif len(net_list) == 0:
        ret['changes'] = __salt__['neutron.network_create'](**net_params)
        ret['comment'] = 'Created new network {0}'.format(name)
    else:
        pp = pprint.PrettyPrinter(indent=4)
        ret['comment'] = 'More than one network with specified parameters '\
                        'already exist:\n{0}'.format(pp.pformat(net_list))
        ret['result'] = False
    return ret
