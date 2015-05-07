TODO
====

- **UPDATE README & TODO**

- Fix issue with SPICE-console

- Turn retrieval of tenant_id from salt-mine into a jinja-macro.

- add sanity checks for pillar on minions. make sure all needed 
  configuration parameters are set in pillar *as seen by the minion*.
  IN PROGRESS

- Update README with info on basic Pillar-data - PARTLY DONE

- Clean up `keystone/files/keystone.conf`. Should use the
  keystone.{user,pass,...} keys in Pillar we need to set anyway
  and overall work more like the newer templates do (for stuff
  like accessing Pillar).

- Specifying `pillar[glance:bind_host]` may cause a connection
  refused for nova-api. Maybe the nova state should also use 
  `pillar[glance:bind_host]`?

- Make RabbitMQ listen only on the internal address of the
  controller

- reduce redundancy in Pillar (get listen addr for neutron-server 
  from neutron.endpoint, get listen addr for keystone from 
  keystone.endpoint, set passwords/tokens to those in 
  {neutron,keystone}.{password,token} and so on) 

- template `neutron/initial_{network,subnet}.sls`

- don't allow networks of same name in the same tenant.
  (not necessary but would only cause confusion and makes
  identifying the correct network hard)

- keep dnsmasq from breaking name-resolution on network node

- Why do several states (keystone, glance, nova.controller, horizon, 
  occasionally openvswitch) need to be run twice to work proberly?? 

- Add users for services in Keystone (missing: cinder, ceilometer, heat?)

- Add endpoints in Keystone (missing: cinder, ceilometer, heat?)

- Add services in Keystone (missing: cinder, ceilometer, heat?)

- Add states for Heat

- Add states for Ceilometer

- write a state-file for the `Orchestrate-Runner`_

.. _Orchestrate-Runner:
    http://docs.saltstack.com/en/latest/topics/tutorials/states_pt5.html#orchestrate-runner

- add support for OpenStack Juno (configured via 
    pillar[openstack:release])

- Add states for Heat?

- Figure out how to run `{keystone,nova,...}-manage db_sync` states
  w/o making the dependent services fail for the next execution b/c
  the DB doesn't work yet.
  Maybe we can use the prereq_ requisite to check if the DB schema
  will change and stop the service(s) beforehand. But I suspect we
  have to wrap some Salt-stuff around the differen migrations-
  mechanisms for this to work.

.. _prereq:
    http://docs.saltstack.com/en/latest/ref/states/requisites.html#prereq

Nice to have
------------
Might be added later: 

  - support for Swift
