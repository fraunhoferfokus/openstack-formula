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

Prepare your hosts
------------------

    - assign hardware and roles
        - TODO: Links to OpenStack HW recommendations
    - plan networks
        - management network: internal communication 
          of services like database access
        - external network: exposes APIs and provides 
          internet access for tenants' instances
    - connect hosts to said networks
        - controller (and network node if on a separate host) 
          to the external and the management network
        - compute nodes only to the management network
    - install OS [0]_
    - create initial user for mgmt
    - add `SaltStack PPA`_ (on Ubuntu) or EPEL_ repositories
      (on RHEL/CentOS) for up-to-date SaltStack packages to 
      all nodes::
        
        sudo apt-get install --yes software-properties-common
        sudo add-apt-repository ppa:saltstack/salt        
        

    - deploy salt-master
        - preferably on a different host than your controller
        - install pkg *salt-master*
        - checkout formulas to */srv/salt/* [2]_
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
          your master [1]_


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
.. [0] We use Ubuntu 14.04, supported just as
       long as OpenStack Icehouse, see Ubuntu's
       `CloudArchive page`_
.. _CloudArchive page: 
    https://wiki.ubuntu.com/ServerTeam/CloudArchive
.. _EPEL: https://fedoraproject.org/wiki/EPEL
.. [1] See the `documentation on the salt-key cmd`_ for details.
.. _documentation on the salt-key cmd: 
    http://docs.saltstack.com/en/latest/ref/cli/salt-key.html
.. [2] If you're comfortable with git you might want to look
       into Salt's GitFS_ backend
.. _GitFS: 
    http://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html

Entering Configuration Details in Pillar
========================================

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
hostname (i.e. */srv/salt/pillar/controller.sls*)
included in its pillar.

Then minions matched by the regex (assuming minion IDs
with just nodenames, not fully qualified domain names)
will get the contents of */srv/salt/pillar/openstack.sls*.
