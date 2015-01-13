# -*- coding: utf-8 -*-
'''

Module for handling openstack neutron calls.

:optdepends:    - neutronclient Python adapter

:configuration: This module is not usable until the following are specified
    either in a pillar or in the minion's config file::

        keystone.user: admin
        keystone.password: verybadpass
        keystone.tenant: admin
        keystone.tenant_id: f80919baedab48ec8931f200c65a50df
        keystone.auth_url: 'http://127.0.0.1:5000/v2.0/'

        OR (for token based authentication)

        keystone.token: 'ADMIN'
        keystone.endpoint: 'http://127.0.0.1:35357/v2.0'

    If configuration for multiple openstack accounts is required, they can be
    set up as different configuration profiles:
    For example::

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

    With this configuration in place, any of the keystone functions can make use
    of a configuration profile by declaring it explicitly.
    For example::

        salt '*' keystone.tenant_list profile=openstack1
:configuration: This module is not usable until '''

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
    Set up keystone credentials

    Only intended to be used within Keystone-enabled modules
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

def create_network(name, admin_state_up = False):
    neutron = auth()
    neutron.format = 'json'
    network = {'name': name, 'admin_state_up': admin_state_up}
    ret = {}
    neutron.create_network({'network':network})
    networks = neutron.list_networks(name=network)
    print networks
    return {'Changes': networks}

def delete_network(network_id):
    neutron = auth()
    neutron.format = 'json'
    neutron.delete_network(network_id)

def list_networks(name = ''):
    neutron = auth()
    neutron.format = 'json'
    if name:
        networks = neutron.list_networks(name = name)
    else:
        networks = neutron.list_networks()
    return networks
