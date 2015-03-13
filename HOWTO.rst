==============================================
How To Use the OpenStack Formula for SaltStack
==============================================

This document describes the whole process of
deploying OpenStack_ using our formula for
SaltStack_.

We assume you're not to familiar with SaltStack.
If you are the information from the README should
be sufficient. If it's not please open an issue.

.. _OpenStack: http://www.openstack.org/
.. _SaltStack: http://www.saltstack.org/

Example configuration values
============================
Here's an overview of the values used in the examples
below:

    - Networks
        - Management: 192.0.2.0/24 (aka TEST-NET-1 [0]_)
        - External: 203.0.113.0/24 (aka TEST-NET-3)
    - IPs:
        - controller: 203.0.113.10 on eth1
        - controller-mgmt: 192.0.2.10 on eth0
        - compute-1: 192.0.2.21 on eth0
        - compute-2: 192.0.2.22 on eth0
    - Default gateways:
        - Management: 192.0.2.1
        - External: 203.0.113.1

.. [0] Subnets reserved for documentation, see `RFC 5737`_
.. _RFC 5737: https://tools.ietf.org/html/rfc5737

Preparation
===========

In order to deploy OpenStack, some preparations are required:

Planning
--------

    - Assign hardware and roles
        - In this example, we will deploy a setup with one controller 
          node that incorporates the network node, and two compute nodes
        - A salt-master host that can be reached from all nodes is 
          required, it could be on an extra host inside the management 
          network, as well as an external host (possibly through a 
          salt-proxy)
        - TODO: Links to OpenStack HW recommendations
    - Plan networks, assign IPs
        - Management network: Internal communication 
          of services (database, internal APIs), packet forwarding 
          between controller and compute nodes
        - External network: Exposes public APIs and provides 
          internet access for OpenStack instances

Prepare your hosts
------------------

    - Connect hosts to the networks you defined
        - Controller (and network node if on a separate host) 
          to the external and the management network
        - Compute nodes only to the management network
    - Install the operating system[1]_, create initial user for
      management
    - Add `SaltStack PPA`_ (on Ubuntu) or EPEL_ repositories
      (on RHEL/CentOS) for up-to-date SaltStack packages to 
      all nodes::
        
        sudo apt-get install --yes software-properties-common
        sudo add-apt-repository ppa:saltstack/salt        
        

    - Deploy salt-master
        - Preferably on a different host than your controller
        - Install package *salt-master*
        - Checkout formulas to */srv/salt/* [3]_
            - `MySQL formula`_
            - `OpenvSwitch formula`_
            - `OpenStack formula`_
            - **TODO**: Use FOKUS repository URLs!
        - Configure your master's *file_roots* in 
          */etc/salt/master*::

            file_roots:
              base:
                - /srv/salt/base
              openstack:
                - /srv/salt/openstack-formula
                - /srv/salt/openvswitch-formula
                - /srv/salt/mysql-formula
                  
    
        - Configure your master's *pillar_roots*::

            pillar_roots:
              base:
                - /srv/salt/pillar
    
        - Restart salt-master

    - Deploy salt-minion on the OpenStack nodes
        - Set hostnames (compute-1.example.com, 
          compute-2.example.com...)
        - Install package *salt-minion*
        - Run *salt-key -L* to list minion-keys on your
          master
        - Run *salt-key -A* to accept minion-keys on
          your master [2]_


You may want to install more packages useful for debugging
and fixing stuff (lsof, multitail, nmap, tmux, openssh-server)
and add your SSH-keys to *~user/.ssh/authorized_keys* now.

As this is a good point to roll back to you may also want
to make a backup or - if you're testing this on VMs - take
a snapshot.

.. _SaltStack PPA:
    https://launchpad.net/~saltstack/+archive/ubuntu/salt
.. _MySQL Formula:
    https://github.com/saltstack-formulas/mysql-formula/
.. _OpenvSwitch Formula: 
    https://github.com/0xf10e/openvswitch-formula
.. _OpenStack formula: 
    https://github.com/0xf10e/openstack-formula
.. [1] We use Ubuntu 14.04 for which Canonical will 
       (according to their `CloudArchive page`_) 
       provide updated packages for OpenStack Icehouse
       for five years.
.. _CloudArchive page: 
    https://wiki.ubuntu.com/ServerTeam/CloudArchive
.. _EPEL: https://fedoraproject.org/wiki/EPEL
.. [2] See the `documentation on the salt-key cmd`_ for details.
.. _documentation on the salt-key cmd: 
    http://docs.saltstack.com/en/latest/ref/cli/salt-key.html
.. [3] If you're comfortable with git you might want to look
       into Salt's GitFS_ backend
.. _GitFS: 
    http://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html

Pillar for Configuration Details
--------------------------------

Pillar data in SaltStack is private to the minions it's
assigned to. Targeting for this assigning can be done in
several ways (for details see `Storing Static Data in the 
Pillar`_) and is done in a top file called *top.sls*
placed in the directory specified unter *pillar_roots* on
the master.

.. _Storing Static Data in the Pillar: 
    http://docs.saltstack.com/en/latest/topics/pillar/

The Topfile
```````````

We start with a rather simple top.sls::

    base:
        '(controller|network|compute-[0-9])':
            - match: pcre
            - openstack
        'compute-?':
            - compute_all
        '*':
            - {{ grains.host }}

Minions matched by the regex (assuming minion IDs with 
just nodenames, not fully qualified domain names) will 
get the contents of `/srv/salt/pillar/openstack.sls`.

Minions matching the glob *compute-?* get the information 
needed on all compute nodes from `/srv/salt/pillar/compute_all.sls`.

All minions get the content of a file with a name equal
to the minions hostname (plus `.sls` like 
`/srv/salt/pillar/controller.sls`) included in its pillar.

Common Configuration Data
`````````````````````````

In `openstack.sls` we define information needed on all hosts::

    openstack:
      release: icehouse
      controller:
        address_int: 192.0.2.10
        address_ext: 203.0.113.10
      rabbitmq:
        host: 192.0.2.10
        password: 'I got my password from the HowTo'

    dns:
      domains:
          - example.com
      servers:
          - 8.8.8.8
          - 8.8.4.4

Compute Nodes
`````````````

In `compute_all.sls` we add options common to all compute-nodes::

    roles:
        - openstack-compute

    keystone.user: nova
    keystone.password: 'Keystone HowTo Password'
    keystone.endpoint: 'http://203.0.113.10:35357/v2.0'
    keystone.auth_url: 'http://203.0.113.10:5000/v2.0'
    keystone.region: 'RegionOne'
    
    openvswitch:
        bridges:
            br-int:
                comment: integration bridge
                ports: 
                    - eth0
                reuse_netcfg: eth0


In `compute-1.sls` and `compute-2.sls` we add options
unique to the particular compute-node.

For `compute-1.sls`::

    nova:
        common:
            DEFAULT:
                my_ip: 192.0.2.21

    interfaces:
        eth0:
            comment: management interface
            ipv4: 192.0.2.21/24
            default_gw: 192.0.2.1

For `compute-2.sls`::

    nova:
        common:
            DEFAULT:
                my_ip: 192.0.2.22
    
    interfaces:
        eth0:
            comment: management interface
            ipv4: 192.0.2.21/24
            default_gw: 192.0.2.1

The Controller
``````````````

In `controller.sls` we define information only available 
to our controller. Those sections you already know::
    
    roles:
        - openstack-controller
        - openstack-network

    interfaces:
        eth0:
            comment: management interface
            ipv4: 192.0.2.10/24
        eth1:
            comment: external interface
            ipv4: 203.0.113.10/24
            default_gw: 203.0.113.1
    
    openvswitch:
        bridges:
            br-int:
                comment: integration bridge
                ports: 
                    - eth0
                reuse_netcfg: eth0
            br-ex:
                comment: external bridge
                ports: 
                    - eth1
                reuse_netcfg: eth1

The Keystone credentials on the controller are based on a 
token which is set in the Keystone configuration file::

    keystone.token: 'Keystone HowTo Token'
    keystone.endpoint: 'http://203.0.113.10:35357/v2.0'
    keystone.auth_url:  'http://203.0.113.10:5000/v2.0'
    keystone.region: 'RegionOne'

Those Neutron credentials are needed to let salt
talk to Neutron. The Neutron *shared_secret* is
for communications between the `neutron-server`
and its metadata-agent::

    neutron.endpoint: 'http://203.0.113.10:9696'
    #neutron.auth_url:  'http://203.0.113.10:5000/v2.0'
    neutron.user: neutron
    neutron.tenant: service
    neutron.password: 'Neutron HowTo Password'

    openstack:
        neutron:
            shared_secret: Shared_secret_from_the_HowTo 

Here are some settings we need for MySQL. We have to specify 
the root password and the bind-address so `mysqld` only listens 
on the management interface. Some encoding related settings are
needed so Glance won't refuse to put its data into the database.
You only need to change *bind-address* and *root_password*::

    mysql:
        server:
            mysqld:
                bind-address:
                    192.0.2.10
                character-set-server:
                    utf8
                collation-server:
                    utf8_general_ci
                default-storage-engine:
                    innodb
                init-connect:
                    SET NAMES utf8
                innodb_file_per_table:
                    True
            root_password:
                rubnaj[swatLaidyalv1


Deployment
==========

Make sure to sync all modules first::

    sudo salt \* saltutil.sync_all saltenv=base,openstack

Configure openvswitch on network and compute nodes::

    sudo salt -C 'I@roles:openstack-compute or I@openstack-compute' \
        state.sls openvswitch saltenv=openstack

Make sure network configuration is correct on all hosts::

    sudo salt \* state.sls networking saltenv=openstack
    
Install MySQL on your controller::
 - mysql


 - rabbitmq
 - keystone, twice?
 - neutron.controller
 - nova.controller, twice
 - neutron.network
 - neutron.compute
 - nova.compute
 - glance, twice
 - horizon (on fail `local_settings.py` try again)
