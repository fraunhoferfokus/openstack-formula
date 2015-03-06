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
        - controller: 203.0.113.10
        - controller-mgmt: 192.0.2.10
        - compute-1: 192.0.2.21
        - compute-2: 192.0.2.22

.. [0] Subnets reserved for documentation, see `RFC 5737`_
.. _RFC 5737: https://tools.ietf.org/html/rfc5737

Preparation
===========
We can't just jump into deploying OpenStack without
making some preparations.

Planing
-------

    - assign hardware and roles
        - TODO: Links to OpenStack HW recommendations
    - plan networks, assign IPs
        - management network: internal communication 
          of services, i.e. like database access
        - external network: exposes public APIs and provides 
          internet access for tenants' instances

Prepare your hosts
------------------

    - connect hosts to the networks you defined
        - controller (and network node if on a separate host) 
          to the external and the management network
        - compute nodes only to the management network
    - install OS [1]_, create initial user for mgmt
    - add `SaltStack PPA`_ (on Ubuntu) or EPEL_ repositories
      (on RHEL/CentOS) for up-to-date SaltStack packages to 
      all nodes::
        
        sudo apt-get install --yes software-properties-common
        sudo add-apt-repository ppa:saltstack/salt        
        

    - deploy salt-master
        - preferably on a different host than your controller
        - install pkg *salt-master*
        - checkout formulas to */srv/salt/* [3]_
            - `MySQL formula`_
            - `OpenvSwitch formula`_
            - `OpenStack formula`_
            - **TODO**: Correct URLs
        - configure your master's *file_roots* in 
          */etc/salt/master*::

            file_roots:
              base:
                - /srv/salt/base
              openstack:
                - /srv/salt/openstack-formula
                - /srv/salt/openvswitch-formula
                - /srv/salt/mysql-formula
                  
    
        - configure your master's *pillar_roots*::

            pillar_roots:
              base:
                - /srv/salt/pillar
    
        - restart salt-master

    - deploy salt-minion on the OpenStack-Nodes
        - set hostnames (compute-1.example.com, 
          compute-2.example.com...)
        - install pkg *salt-minion*
        - run *salt-key -L* to list minion-keys on your
          master
        - run *salt-key -A* to accept minion-keys on
          your master [2]_


You may want to install more packages useful for debugging
and fixing stuff (lsof, multitail, nmap, tmux, openssh-server)
and add your SSH-keys to *~user/.ssh/authorized_keys* now.

As this is a good point to roll back to you may also want
to make a backup or (if you're testing this on VMs) take
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

Entering Configuration Details in Pillar
----------------------------------------

Pillar data in SaltStack is private to the minions it's
assigned to. Targeting for this assigning can be done in
several ways (for details see `Storing Static Data in the 
Pillar`_) and is done in a top file called *top.sls*
placed in the directory specified unter *pillar_roots* on
the master.

.. _Storing Static Data in the Pillar: 
    http://docs.saltstack.com/en/latest/topics/pillar/

We go with a rather simple top file::

    base:
        '*':
            - {{ grains.host }}
        '(controller|network|compute-[0-9])':
            - match: pcre
            - openstack

First any node get's the content of a file with its
hostname (i.e. `/srv/salt/pillar/controller.sls`)
included in its pillar.

Then minions matched by the regex (assuming minion IDs
with just nodenames, not fully qualified domain names)
will get the contents of `/srv/salt/pillar/openstack.sls`.

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

In `controller.sls` we define information only available 
to our controller::
    
    roles:
        - openstack-controller
        - openstack-network

    keystone.token: 'Keystone HowTo Token'
    keystone.endpoint: 'http://203.0.113.10:35357/v2.0'
    keystone.auth_url:  'http://203.0.113.10:5000/v2.0'
    keystone.region: 'RegionOne'

    neutron.endpoint: 'http://203.0.113.10:9696'
    #neutron.auth_url:  'http://203.0.113.10:5000/v2.0'
    neutron.user: neutron
    neutron.tenant: service
    neutron.password: 'Neutron HowTo Password'


    openstack:
        neutron:
            shared_secret: Shared_secret_from_the_HowTo 



In `compute_all.sls` we add options common to all compute-nodes::

    roles:
        - openstack-compute

    keystone.user: nova
    keystone.password: 'Keystone HowTo Password'
    keystone.endpoint: 'http://203.0.113.10:35357/v2.0'
    keystone.auth_url: 'http://203.0.113.10:5000/v2.0'
    keystone.region: 'RegionOne'


In `compute-1.sls` and `compute-2.sls` we add options
unique to the particular compute-node.

For `compute-1.sls`::

    nova:
        common:
            DEFAULT:
                my_ip: 192.0.2.21

For `compute-2.sls`::

    nova:
        common:
            DEFAULT:
                my_ip: 192.0.2.22


Deploytment
===========

Make sure to sync all modules first::

    sudo salt \* saltutil.sync_all saltenv=base,openstack

...
