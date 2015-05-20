# -*- coding: utf-8 -*-
'''
Managing routers in OpenStack Neutron
=====================================
'''
# Import python libs
import logging
import pprint
#import yaml

# Import salt libs
import salt.utils
import salt.utils.templates

import neutronclient.common.exceptions as neutron_exceptions

log = logging.getLogger(__name__)

def managed(name, admin_state_up = None, tenant_id = None, 
        subnet_ids = [], port_ids = [],
        gateway_network = None, enable_snat = None):
    '''
    Manage routers in OpenStack Neutron

    Required parameter: 
    - name

    Optional parameters:
    - admin_state_up*
    - tenant_id (only works for admin-users)
    - gateway_network (network_id of external network)
    - enable_snat*

    TODO: use router_add_interface() to add subnets and ports
    
    *) defaults to True in neutron.router_create
    '''
    ret = { 'name': name,
        'changes': {},
        'result': True,
        'comment': ''}
    pp = pprint.PrettyPrinter(indent=4)
    
    list_filters = {'name': name}
    if admin_state_up is not None:
        list_filters['admin_state_up'] = admin_state_up
    if tenant_id is not None:
        list_filters['tenant_id'] = tenant_id
    router_list = __salt__['neutron.router_list'](**list_filters)['routers']
    router_params = list_filters.copy()
    if gateway_network is not None:
        router_params['gateway_network'] = gateway_network
    if enable_snat is not None:
        router_params['enable_snat'] = enable_snat
    if len(router_list) == 0:
        log.debug('Creating router with those parameters: \n' +\
                '{0}'.format(pp.pformat(router_params)))
        router = __salt__['neutron.router_create'](**router_params)
        if router.has_key('router'):
            router = router['router']
        log.debug('New router: {0}'.format(router))
        ret['comment'] = 'Created new router.'
        # TODO: Add subnets/ports HERE
        ret['changes'] = __salt__['neutron.router_show'](router['id'])
    elif len(router_list) == 1:
        # TODO: check if admin_state_up has the correct value and if
        # correct subnets and ports exist.
        log.debug('Found one router "{0}" '.format(name) +\
                'with following properties: \n{0}'.format(
                    pp.pformat(router_list[0])))
        ret['comment'] = 'Router "{0}" already exists.'.format(name) +\
                '\n(ID: {0})'.format(router_list[0]['id']) +\
                '\n(Checking attributes not implemented yet!)'
        # TODO: modify ret['changes'] as needed
    else:
        ret['result'] = False
        ret['comment'] = 'More than one router with this name already ' +\
                'exists in this tenant. See debug information for details.'
        log.debug('Existing routers: \n{0}'.format(pp.pformat(router_list)))
    return ret
