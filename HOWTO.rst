How To Use the OpenStack Formula for SaltStack
==============================================

This document describes the whole process of
deploying OpenStack_ using our formula for
SaltStack.

.. _OpenStack: http://www.openstack.org/

Prepare your hosts
------------------

    - assign hardware and roles
        - TODO: Links to OpenStack HW recommendations
    - plan networks
        - management network
        - external network
    - connect hosts to said networks
    - install OS
    - create initial user for mgmt
    - add `SaltStack PPA`_ to all nodes::
        
        sudo apt-get install --yes software-properties-common
        sudo add-apt-repository ppa:saltstack/salt        
        

    - salt-master (preferable on a different host)
        - install pkg *salt-master*
        - clone formulas to */srv/salt/*
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

    - salt-minion on the OpenStack-Nodes
        - set hostnames (compute-1.example.com, 
          compute-2.example.com...)
        - install pkg *salt-minion*
        - run *salt-key -L* to list minion-keys on your
          salt-master
        - run *salt-key -A* to accept minion-keys

You may want to install more packages useful for debugging
and fixing stuff (lsof, multitail, nmap, tmux, openssh-server)
and add your SSH-keys to *~user/.ssh/authorized_keys* now.

As this is a good point to roll back to you may also want
to make a backup or (if you're testing this on VMs) take
a snapshot.

.. _SaltStack PPA: https://launchpad.net/~saltstack/+archive/ubuntu/salt
.. _MySQL Formula: https://github.com/saltstack-formulas/mysql-formula/
.. _OpenvSwitch Formula: https://github.com/0xf10e/openvswitch-formula
.. _OpenStack formula: https://github.com/0xf10e/openstack-formula

Entering Configuration Details in Pillar
========================================

Bla bla bla...
