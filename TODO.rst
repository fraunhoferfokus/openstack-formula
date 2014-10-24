TODO
----

- Add endpoints in Keystone (missing: glance, neutron)

- Figure out how to run `{keystone,nova,...}-manage db_sync` states
  w/o making the dependent services fail for the next execution b/c
  the DB doesn't work.

- create service accounts in keystone (missing: glance, neutron?)

- add OVS-bits to neutron.server

- write a state for the Orchestrate-Runner_

.. _Orchestrate-Runner:
    http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner
