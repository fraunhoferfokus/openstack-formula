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

def managed(name, admin_state_up = None, tenant = None, 
        subnet_ids = [], port_ids = [],
        gateway_network = None, enable_snat = None):
    '''
    Manage routers in OpenStack Neutron

    Required parameter: 
    - name

    Optional parameters:
    - admin_state_up*
    - tenant (only works for admin-users)
    - gateway_network (name of external network)
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
    if tenant is not None:
        # Workaround for https://github.com/saltstack/salt/issues/24568
        tenant_dict = __salt__['keystone.tenant_get'](name=tenant)
        if tenant_dict.has_key(tenant):
            tenant_dict = tenant_dict[tenant]
        try:
            list_filters['tenant_id'] = tenant_dict['id']
        except KeyError:
            raise KeyError, 'no key "id": ' + str(tenant_dict)
    router_list = __salt__['neutron.router_list'](**list_filters)
    router_params = list_filters.copy()
    if gateway_network is not None:
        router_params['gateway_network'] = \
            __salt__['neutron.network_show'](name=gateway_network)['id']
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
        router = router_list[0]
        to_update = {}
        if admin_state_up is not None and \
                router.admin_state_up != admin_state_up:
            to_update['admin_state_up'] = admin_state_up
        if gateway_network is not None or enable_snat is not None:
            if router.has_key('external_gateway_info') and \
                    router['external_gateway_info'] is not None and \
                    (
                    router['external_gateway_info']['network_id'] != \
                    gateway_network or \
                    router['external_gateway_info']['enable_snat'] != \
                    enable_snat):
                to_update['external_gateway_info'] = {
                    'network_id': \
                        __salt__['neutron.network_show'](
                            name = gateway_network)['id'],
                    'enable_snat': enable_snat,
                    }
        ret['comment'] = 'Router "{0}" already exists.'.format(name) +\
                '\n(ID: {0})'.format(router_list[0]['id'])
        if to_update:
            log.debug('Those properties need to be ' +\
                'changed on router {0}: \n{1}'.format(name,
                    pp.pformat(to_update)))
            router_id = router.pop('id')
            if to_update.has_key('external_gateway_info'):
                ext_net_props = to_update.pop('external_gateway_info')
                to_update['gateway_network'] = ext_net_props['network_id']
                to_update['enable_snat'] = ext_net_props['enable_snat']
            updated = __salt__['neutron.router_update'](
                    router_id, **to_update)['router']
            log.debug('Updated router {0}: \n{1}'.format(name, pp.pformat(
                updated)))
            for key in ['name', 'routes', 'status', 'tenant_id']:
                if updated.has_key(key) and \
                        router[key] != updated[key]:
                    ret['changes'][key] = updated[key]
            if updated.has_key('external_gateway_info'):
                changed_gw_info = {}
                if router['external_gateway_info']['network_id'] != \
                        updated['external_gateway_info']['network_id']:
                    changed_gw_info['network_id'] = \
                        updated['external_gateway_info']['network_id']
                if router['external_gateway_info']['enable_snat'] != \
                        updated['external_gateway_info']['enable_snat']:
                    changed_gw_info['enable_snat'] = \
                        updated['external_gateway_info']['enable_snat']
                ret['changes']['external_gateway_info'] = \
                    changed_gw_info
    else:
        ret['result'] = False
        ret['comment'] = 'More than one router with this name already ' +\
                'exists in this tenant. See debug information for details.'
        log.debug('Existing routers: \n{0}'.format(pp.pformat(router_list)))
    return ret
