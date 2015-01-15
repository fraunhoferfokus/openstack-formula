TODO
====

- **UPDATE README & TODO**

- don't allow networks of same name in the same tenant

- implement neutron.network_modify and adjusting existing
  networks with neutron_network.managed

- implement neutron.subnet_modify and neutron_subnet.managed

- keep dnsmasq from breaking name-resolution on network node

- Update README with info on basic Pillar-data

- Add states for Cinder

- Add states for Ceilometer

- Add states for Heat

- Add users for services in Keystone (missing: cinder, ceilometer, heat?)

- Add endpoints in Keystone (missing: cinder, ceilometer, heat?)

- Add services in Keystone (missing: cinder, ceilometer, heat?)

- Figure out how to run `{keystone,nova,...}-manage db_sync` states
  w/o making the dependent services fail for the next execution b/c
  the DB doesn't work yet.
  Maybe we can use the prereq_ requisite to check if the DB schema
  will change and stop the service(s) beforehand. But I suspect we
  have to wrap some Salt-stuff around the differen migrations-
  mechanisms for this to work.

.. _prereq:
    http://docs.saltstack.com/en/latest/ref/states/requisites.html#prereq

- write a state-file for the Orchestrate-Runner_

.. _Orchestrate-Runner:
    http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner

Nice to have
------------
Might be added later: 

  - support for Swift
  - support for different versions of OpenStack (configured via 
    pillar[openstack:release])
