TODO
----

- Add endpoints in Keystone

- Figure out how to run `{keystone,nova,...}-manage db_sync` states
  w/o making the dependent services fail for the next execution b/c
  the DB doesn't work.

- Uncomment `keystone-dbuser` and its appearance in `keystone-grants`' 
  `require`-list after https://github.com/saltstack/salt/issues/16676
  is fixed

- create service accounts in keystone

- add OVS-bits to neutron.server

