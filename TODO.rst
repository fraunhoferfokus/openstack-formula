TODO
====

- Update README with info on basic Pillar-data

- Add states for Cinder

- Add states for Ceilometer

- Add states for Heat

- Add users for services in Keystone (missing: cinder, ceilometer, heat?)

- Add endpoints in Keystone (missing: cinder, ceilometer, heat?)

- Add services in Keystone (missing: cinder, ceilometer, heat?)

- add OVS-bits to neutron.server

- Figure out how to run `{keystone,nova,...}-manage db_sync` states
  w/o making the dependent services fail for the next execution b/c
  the DB doesn't work yet.

- write a state-file for the Orchestrate-Runner_

.. _Orchestrate-Runner:
    http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner

Nice to have
------------
Might be added later: 

  - support for Swift
  - support for different versions of OpenStack (configured via 
    pillar[openstack:release])
