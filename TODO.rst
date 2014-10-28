TODO
----

- Add users for services in Keystone (missing: cinder, ceilometer, heat?)

- Add endpoints in Keystone (missing: cinder, ceilometer, heat?)

- Add services in Keystone (missing: cinder, ceilometer, heat?)

- Figure out how to run `{keystone,nova,...}-manage db_sync` states
  w/o making the dependent services fail for the next execution b/c
  the DB doesn't work yet.

- add OVS-bits to neutron.server

- write a state for the Orchestrate-Runner_

.. _Orchestrate-Runner:
    http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner
