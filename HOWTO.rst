==============================================
How To Use the OpenStack Formula for SaltStack
==============================================

This document describes the whole process of
deploying OpenStack_ using `our formula`_ for
SaltStack_.

We assume you're not to familiar with SaltStack.
If you are the information from the README should
be sufficient. If it's not please open an issue.

.. _OpenStack: http://www.openstack.org/
.. _SaltStack: http://www.saltstack.org/
.. _our formula:
  https://github.com/fraunhoferfokus/openstack-formula

TODO
====

 - fix this:: 

    root@hw-ctrl:~# neutron agent-list
    {"error": {"message": "The request you have made requires\
     authentication.", "code": 401, "title": "Unauthorized"}}
    root@hw-ctrl:~#

   caused by missing `neutron:keystone_authtoken:admin_password`
   to set `/etc/nova/nova.conf:neutron_admin_password`

 - and this::

     root@hw-ctrl:~# nova list
     ERROR: Invalid OpenStack Nova credentials.

   caused by missing `neutron:server:DEFAULT:nova_admin_password` to set
   `/etc/neutron/neutron.conf:nova_admin_password`

 - missing `/etc/neutron/metadata_agent.ini:admin_password` can't help
   either...

 - remove section TODO

Example configuration values
============================
Here's an overview of the values used in the examples
below you have to replace with your own:

    - Networks
        - Management: 192.0.2.0/24 (aka TEST-NET-1 [0]_)
        - External: 203.0.113.0/24 (aka TEST-NET-3)
    - IPs:
        - salt: 192.0.2.2
        - controller: 203.0.113.10 on eth1
        - controller-mgmt: 192.0.2.10 on eth0
        - compute-1: 192.0.2.21 on eth0
        - compute-2: 192.0.2.22 on eth0
    - Default gateways:
        - Management: 192.0.2.1
        - External: 203.0.113.1

TODO: Add passwords an so on.

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

Network
```````

    - Connect hosts to the networks you defined
        - Controller (and network node if on a separate host) 
          to the external and the management network
        - Compute nodes and Salt master only to the management 
          network
    - Install the operating system [1]_, create initial user for
      management
    - Add `SaltStack PPA`_ (on Ubuntu) or EPEL_ repositories
      (on RHEL/CentOS) for up-to-date SaltStack packages to 
      all nodes::
        
        sudo apt-get install --yes software-properties-common
        sudo add-apt-repository ppa:saltstack/salt        


``salt-master``
```````````````

        - Preferably on a different host than your controller
        - Install package *salt-master*
        - Checkout formulas to */srv/salt/* [3]_
            - `MySQL formula`_
            - `OpenvSwitch formula`_
            - `OpenStack formula`_
        - Configure your master's ``file_roots`` in
          ``/etc/salt/master``::

            file_roots:
              base:
                - /srv/salt/base
              openstack:
                - /srv/salt/openstack-formula
                - /srv/salt/openvswitch-formula
                - /srv/salt/mysql-formula
                  
        - Configure your master's ``pillar_roots`` [6]_::

            pillar_roots:
              base:
                - /srv/salt/pillar
    
        - Restart salt-master

.. [6] See `Pillar for Configuration Details`_ and
    `Storing Static Data in the Pillar`_ for more
    information on Salt's Pillar

``salt-minion``
```````````````

On the OpenStack nodes:
        - Set hostnames (compute-1.example.com, 
          compute-2.example.com...)
        - Install package ``salt-minion``
        - Point your minions to your master, add those
          lines to ``/etc/salt/minion``::
            
            master:
                - 192.0.2.2

        - Restart the salt-minion service
        - Run *salt-key -L* to list minion-keys on your
          master
        - Run *salt-key -A* to accept minion-keys on
          your master [2]_

You may want to install more packages useful for debugging
and fixing stuff (lsof, multitail, nmap, tmux, openssh-server)
and add your SSH-keys to ``~user/.ssh/authorized_keys`` now.

As this is a good point to roll back to you may also want
to make a backup or - if you're testing this on VMs - take
a snapshot.

.. _SaltStack PPA:
    https://launchpad.net/~saltstack/+archive/ubuntu/salt
.. _MySQL Formula:
    https://github.com/saltstack-formulas/mysql-formula.git
.. _OpenvSwitch Formula: 
    https://github.com/fraunhoferfokus/openvswitch-formula.git
.. _OpenStack formula: 
    https://github.com/fraunhoferfokus/openstack-formula
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
Pillar`_) and is done in a top file called ``top.sls``
placed in the directory specified under ``pillar_roots`` on
the master::

    op@master:~% grep -A 2 '^pillar_roots' /etc/salt/master
    pillar_roots:
      base:
        - /srv/salt/pillar

Thus our topfile is ``/srv/salt/pillar/top.sls``.

.. _Storing Static Data in the Pillar: 
    http://docs.saltstack.com/en/latest/topics/pillar/

Our Topfile
```````````

We start with a rather simple ``top.sls``::

    base:
        '(controller|network|compute-[0-9])':
            - match: pcre
            - openstack
        'compute-?':
            - compute_all
        '*':
            - {{ opts.is }}

Minions matched by the regex (assuming minion IDs with
just nodenames, not fully qualified domain names) will
get the contents of ``/srv/salt/pillar/openstack.sls``.

Minions matching the glob ``compute-?`` get the information
needed on all compute nodes from ``/srv/salt/pillar/compute_all.sls``.

All minions get the content of a file with a name equal
to the minions ID (plus ``.sls`` like
``/srv/salt/pillar/controller.sls``) included in its pillar.

Common Configuration Data
`````````````````````````

In `openstack.sls` we define information needed on all hosts::

    openstack:
      release: icehouse
      region_name: RegionOne
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

    nova:
      database:
        password: 'HowTo-Nova-DB-Password'
      keystone_authtoken:
        admin_password: 'Nova HowTo Password'

    keystone.user: 'admin'
    keystone.password: 'Howto Pass'
    keystone.tenant: 'admin'
    keystone.endpoint: 'http://203.0.113.10:35357/v2.0'
    keystone.auth_url: 'http://203.0.113.10:5000/v2.0'
    keystone.region_name: 'RegionOne'

The `keystone.{user,password,...}` part is use on the salt-minion 
on the compute nodes uses these credentials to get data from Keystone. 
They're also used for the Nova configuration and for the openstack salt modules using these as admin credentials.

Compute Nodes
`````````````

In `compute_all.sls` we add options common to all compute-nodes.
We assign their role and specify an OVS bridge *br-int* should 
be create with the interface *eth0* as a port and reuse the
configuration of this interface::

    roles:
        - openstack-compute

    openvswitch:
        bridges:
            br-int:
                comment: integration bridge
                ports: 
                    - eth0
                reuse_netcfg: eth0
    neutron.password: 'Neutron HowTo Password'
    
In `compute-1.sls` and `compute-2.sls` we add options
unique to the particular compute-node.

For `compute-1.sls`::

    openstack:
        common:
            my_ip: 192.0.2.21

    interfaces:
        eth0:
            comment: management interface
            ipv4: 192.0.2.21/24
            default_gw: 192.0.2.1

For `compute-2.sls`::

    openstack:
        common:
            my_ip: 192.0.2.22
    
    interfaces:
        eth0:
            comment: management interface
            ipv4: 192.0.2.21/24
            default_gw: 192.0.2.1

The Controller
``````````````

In `controller.sls` we define information only available 
to our controller. The whole subsection is only about
this one file.

Those are values for pillar-keys you already know::
    
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

    nova:
        neutron_admin_password: "Neutron HowTo Password"

The controller uses a token which is set in the Keystone 
configuration file to add users, endpoints and so on.
Add the token to ``controller.sls`` like this::

    keystone.token: 'Keystone HowTo Token'

Keystone also needs to know the password for its database
and the password for its admin-user. Add those, too::

    keystone:
        database:
            password: 'HowTo Keystone DB Pass'
        admin_password: 'HowTO Keystone Pass'

Those Neutron credentials are needed to let salt
talk to Neutron. The Neutron *shared_secret* is
for communications between the `neutron-server`
and its metadata-agent::

    neutron.endpoint: 'http://203.0.113.10:9696'
    #neutron.auth_url:  'http://203.0.113.10:5000/v2.0'
    neutron.user: neutron
    neutron.tenant: service
    neutron.password: 'Neutron HowTo Password'
    neutron:
        database:
            password: 'Neutron HowTo Password'
        nova_admin_password: 'Nova HowTo Password'
    openstack:
        neutron:
            shared_secret: Shared_secret_from_the_HowTo 

If you want salt to deploy initial networks, you have to
define your networks, subnets and routers::

    neutron:
        networks:
            shared_int_net:
                admin_state_up: True
                shared: True
                tenant: admin
                network_type: gre
    
            shared_ext_net:
                admin_state_up: True
                shared: True
                tenant: admin
                network_type: flat
                external: True
                physical_network: External

        routers:
            shared_ext2int:
                tenant: admin
                gateway_network: shared_ext_net

        subnets:
            shared_int_subnet:
                cidr: 192.168.42.0/24
                network: shared_int_net
                enable_dhcp: True
                tenant: admin

            shared_ext_subnet:
                cidr: 203.0.113.0/24
                network: shared_ext_net
                enable_dhcp: True
                tenant: admin
                allocation_pools:
                    - 203.0.113.5-203.0.113.200

Here are some settings we need for MySQL. We have to specify 
the root password and the bind-address so `mysqld` only listens 
on the management interface. Some encoding related settings are
needed so Glance won't refuse to put its data into the database.
The entry *mysql.pass* is for the Salt MySQL-module used to
create the needed databases. You probably want to set this
entry to the same value as *root_password*.

You only need to change *bind-address*, *root_password* and
*mysql.pass*::

    mysql.pass: 'rubnaj[swatLaidyalv1'
    
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
                'rubnaj[swatLaidyalv1'

Speaking of MySQL - Glance also needs to know the
password for its database and its Keystone user::

    glance:
        database:
            password:
                glance_db_pass
        keystone_authtoken:
            admin_password:
                howto_service_pass_glance

If you want to deploy cinder, you will also need
the following entries for cinder::

    cinder:
        admin_password: 'Howto Pass'
        api_port: 8776
        database:
            password: 'Howto Pass'
            user: 'cinder'
            name: 'cinder'
        nfs_shares_config: 'nfsshares'
        rpc_backend: 'rabbit'
        volume_driver: 
            'cinder.volume.drivers.lvm.LVMISCSIDriver'
        volume_group: 'cinder-volumes'
        keystone_authtoken:
            admin_password: 'Howto Pass'

TODO: Not sure if special characters in
pillar[mysql:server:root_password] work 
in all configfiles...

How to Check Your Pillar
````````````````````````

First check if your minions are complaining about something
pillar-related::

    root@master:~# salt \* pillar.items _errors
    compute-1:
        ----------
    compute-2:
        ----------
    controller:
        ----------

All your minions returning only those empty
sets/only delimiters? Then you're good [5]_.

.. [7] Any occuring errors with Pillar need to
    be resolved before you can continue. Search
    the `Salt documentation`_, the archives of
    the Google Groups/`mailinglist "salt-users"`_
    or try the IRC channel #salt on
    `freenode.net`_.

.. _Salt documentation: http://docs.saltstack.com
.. _`mailinglist "salt-users"`:
    https://groups.google.com/forum/#!forum/salt-users
.. _`freenode.net`: https://freenode.net/

To get the complete pillar of a certain minion
run the following (where "controller" is the
ID of the minion we're targeting here)::

    root@master:~# salt controller pillar.items

To check only on the (input data for the minion's)
network configuration try::

    root@master:~# salt controller pillar.items \
        dns interfaces
    controller:
        ----------
        dns:
            ----------
            domains:
                - example.com
            servers:
                - 8.8.8.8
                - 8.8.4.4
        interfaces:
            eth0:
                comment: management interface
                ipv4: 192.0.2.10/24
            eth1:
                comment: external interface
                ipv4: 203.0.113.10/24
                default_gw: 203.0.113.1

Deployment
==========

.. note:: While we plan to use it later we have some issues 
        with the `orchestrate runner`_ of SaltStack [4]_.
        Deploying this way is more unreliable so for now 
        we stick to running the states manually.

.. [4] Yes, we could use `state.highstate` and define requirements
        between components of OpenStack. But requiring something
        being done on a different host would involve passing
        data around through the `Salt Mine`_ and make the whole
        thing more difficult to debug.

.. _orchestrate runner: 
    http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner
.. _Salt Mine: http://docs.saltstack.com/en/latest/topics/mine/


Make sure to sync all modules first::

    sudo salt \* saltutil.sync_all saltenv=base,openstack

Then tell all minions to refresh their Pillar-data,
just in case::

    sudo salt \* saltutil.refresh_pillar

Generate the network configuration files from
your Pillar::

    sudo salt state.sls \* networking.config && \
        sudo salt \* state.sls networking.resolvconf

Take a look on the returned data and check if
the changes made to configuration files look
reasonable.

.. note:: Now would be a good point to make another backup
    of your setup as the nodes should come up with the
    correct static IP addresses assigned at boot.

The next step is creating the OpenvSwitch bridges.
As we have to re-assign IP addresses "in flight"
you may loose connectivity::

    sudo salt -C \
        'I@roles:openstack-network or I@roles:openstack-compute' \
        state.sls openvswitch saltenv=openstack

Make sure your controller is still online.
If it isn't you have to login locally/over the other
interface and run ``sudo ovs-vsctl del-port br-ex eth1``
(with "eth1" being the interface used for the external
network) and reboot the host. Afterwards running the
``salt`` command above should work.

Now that we have the bridges (you can check with ``salt \*
ovs.bridge show``) we need to regenerate the hosts'
network configuration files::

    sudo salt \* state.sls networking.config saltenv=openstack
    
Keystone
--------

Install MySQL, RabbitMQ and Keystone on your controller::

    sudo salt -I roles:openstack-controller \
        state.sls mysql saltenv=openstack && \
    sudo salt -I roles:openstack-controller \
        state.sls rabbitmq saltenv=openstack && \
    sudo salt -I roles:openstack-controller \
        state.sls keystone saltenv=openstack

If the *keystone* fails re-run the state [5]_::

    sudo salt -I roles:openstack-controller \
        state.sls keystone saltenv=openstack

Test Keystone by running the `keystone.endpoint_list` function
on the controller. If you see similiar output Keystone works:: 

    user@master: ~$ sudo salt -I roles:openstack-controller \
        keystone.endpoint_list
    controller:
        ----------
        1d78ce00dbb642fc95408afaa6c9a1b3:
            ----------
            adminurl:
                http://192.0.2.10:35357/v2.0
            id:
                1d78ce00dbb642fc95408afaa6c9a1b3
            internalurl:
                http://192.0.2.10:5000/v2.0
            publicurl:
                http://203.0.113.10:5000/v2.0
            region:
                RegionOne
            service_id:
                8ee50c9c787b4d46bb7300b57c83644f

Neutron on the Controller
-------------------------

Deploy `neutron-server` on the controller::

    sudo salt -I roles:openstack-controller \
        state.sls neutron.controller saltenv=openstack

To create initial networks run::

    sudo salt -I roles:openstack-controller \
        state.sls neutron.initial_networks

.. note:: There are currently some issues with Allocation
    Pools not being created or updated.

Nova on the Controller
----------------------

Deploy the controller parts of Nova::

    sudo salt -I roles:openstack-controller \
        state.sls nova.controller saltenv=openstack


If you see high CPU-usage of the service `nova-consoleauth`
re-run the state *nova.controller* [5]_.

.. [5] It seems some parts of OpenStack start up too fast or
       rather the tools managing database schemas return
       before the database is done applying the changes.
       This leads to services no working correctly until
       restarted.
        
       For now re-applying the states works in all cases.

Cinder
------

Deploy Cinder on the controller::

    sudo salt -I roles:openstack-controller \
        state.sls cinder saltenv=openstack

Neutron agents on network-node::
    
    sudo salt -I roles:openstack-network \
        state.sls neutron.network saltenv=openstack

Neutron on the Compute-Nodes
----------------------------

Neutron agents on compute-nodes::
    
    sudo salt -I roles:openstack-compute \
        state.sls neutron.compute saltenv=openstack

Nova on the Compute-Nodes
-------------------------

`nova-compute`::

    sudo salt -I roles:openstack-compute \
        state.sls nova.compute saltenv=openstack

Glance
------

Glance on controller [5]_::

    sudo salt -I roles:openstack-controller \
        state.sls glance saltenv=openstack

Horizon
-------
Horizon (if generating `local_settings.py` fails try again [5]_)::

    sudo salt -I roles:openstack-controller \
        state.sls horizon saltenv=openstack

Deploy initial networks::
    
    sudo salt -I roles:openstack-network \
        state.sls neutron.initial_networks saltenv=openstack

Next Steps
----------

Now you should be able to login on the Horizon webinterface on your
controller, to upload images, create networks and spawn instances.

  - Start with navigating to 
    *http://controller.example.com/horizon/project/images/* 
    and upload a small image like Cirros_
  - Go to http://controller.example.com/horizon/project/networks/ 
    and add a tenant network and subnet
  - Add a router to your subnet with the external network as gateway
  - Go back to images, click "Launch" on the one you just uploaded
    and enter some details for your VM
  - Go to the VMs console. Login and check network connectivity
  - Assign a floating IP to the VM and try to connect to the VM
    via SSH using the floating IP

.. _Cirros: https://launchpad.net/cirros
