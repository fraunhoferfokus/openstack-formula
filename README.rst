=================
openstack-formula
=================

A saltstack formula to deploy OpenStack.
Supported components are:
    
  - Keystone
  - Nova
  - Neutron
  - Glance
  - Horizon
  - Cinder

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

.. note::
    
    This formula uses the openvswitch-formula_ and the mysql-formula_ and 
    assumes both are present in the same Salt-Environment.

.. note::

    For now the formula is only tested on Ubuntu 14.04. Don't hesitate to
    add correct package-names for other distributions like CentOS.

.. _openvswitch-formula: https://github.com/saltstack-formulas/openvswitch-formula
.. _mysql-formula: https://github.com/saltstack-formulas/mysql-formula

Pillar-Data common between States
=================================
Some settings are used by several or even all states - like the address of 
the controller. We grouped those under the pillar-key ``openstack`` and
in many places those common settings are used if no value specific for
the given service is found in your Pillar.

Minimal common Pillar::

    openstack:
        controller_address: controller.example.com
        rabbitmq:
            password: 'blVobc_common_pX8_rabbitmq_Trhtj_password_UW1guAQ'
        neutron:
            shared_secret: 'I took my Shared Secret from the documentation'

Pillar-Data for underlying Formulas
===================================

For the state `mysql.server` from the mysql-formula::

    mysql.pass: 'I got my mysql-password from the README'
    mysql:
        server:
            mysqld:
                bind-address: 0.0.0.0
                character-set-server: utf8
                collation-server: utf8_general_ci
                default-storage-engine: innodb
                init-connect: 'SET NAMES utf8'
                innodb_file_per_table: True
            # You obviously need to chose s/t else:
            root_password: 'I got my mysql-password from the README'

.. note:: If you've already installed MySQL or ran the state `mysql.server`
        before you set the pillar `mysql:server:root_password` you may
        have to reset the root-password for MySQL yourself.

Available states
================

.. contents::
    :local:

``pkgrepo``
-----------
Add repositories like Ubuntu's `Cloud Archive`_ if necessary.

.. _Cloud Archive: https://wiki.ubuntu.com/ServerTeam/CloudArchive

``mysql``
---------
Install and configure MySQL for use with OpenStack.

``rabbitmq``
------------
Install and configure RabbitMQ for use with OpenStack.

``keystone``
------------

.. note:: Run the states `mysql` and `rabbitmq` before you 
    try to run the `keystone`-state.

Install and configure OpenStack's Keystone and it's database.

Minimal data for Pillar::

    # This one is for the 'keystone' salt-module, but also used
    # in the keystone-related states (like creating tenants):
    keystone.token: 'eejTij<_keystone_admin_token_>xkigoj3Og1'

    keystone:
      admin_password: '3frajn_<also the admin passwd for the webUI>_R9aGwW'
      database: 
        password: 'sUlPalrGnWTnsg_keystone_db_pass_lTNA2Zse7XkGlA'

``neutron.controller``
------------------
Install and configure the server-part of OpenStack's Neutron 
on the your controller. The MTU is needed because we use 
tunneling.

Minimal state-specific Pillar::

    neutron:
      common:
        DEFAULT:
          admin_password: service_bFdYs/+LF0kaD_pass
        database:
          password: neutron_qg2bD0_database_gCwXD_pass
      dhcp_agent:
        dnsmasq:
          mtu: 1400

``neutron.network``
-------------------
**TODO**

Network node.

``neutron.network``
-------------------
**TODO**

Network node.

``glance``
----------
Install and configure OpenStack's Glance.

Minimal state-specific Pillar::

    glance:
      database:
        password: glance_db_pass
      keystone:
        admin_password: glance_IotdLq_service_Df2HN2_pass

``nova.controller``
-------------------
Install and configure Nova services on the controller.

Minimal data to set in Pillar::

    nova:
      database:
        password: 'Pkbcj5QBD+69pQ_nova_db_pass_UqjG5OzxyPzn3A'

To make IDs of tenants in keystone available for templating
on other nodes add this to the controllers minion-config or
Pillar::

    mine_functions:
      keystone.tenant_list: []


``nova.compute``
----------------

Minimal data to set in Pillar::

    nova:
      DEFAULT:
        # The internal IP of each compute-node:
        my_ip: 1.2.3.4      


``cinder``
----------
The ``cinder`` state checks if at least on or 'cinder-controller'
and 'cinder-node' is in your pillar[roles].

The OpenStack default it to use iSCSI on LVM volumes.
If you want to use NFS instead use settings like these::

    cinder:
        volume_driver: cinder.volume.drivers.nfs.NfsDriver
        nfs_shares:
            server1: /vol/share1
            server2:
                - /vol/share2a
                - /vol/share2b
            server3:
                - /vol/share3


