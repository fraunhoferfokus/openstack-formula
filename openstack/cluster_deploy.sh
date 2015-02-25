# - sync modules via `salt \* saltutil.sync_all openstack`
# - salt \* cmd.run 'echo service salt-minion restart | at now'
# - sudo salt-run state.orch openstack.cluster_deploy openstack
# - ifup/down internal interface and restart mysql or simply 
#   reboot the controller
# - sudo salt-run state.orch openstack.cluster_deploy openstack
# - sudo salt-run state.orch openstack.cluster_deploy openstack
# - sudo salt-run state.orch openstack.cluster_deploy openstack
# - sudo salt-run state.orch openstack.cluster_deploy openstack
# - salt 'compute-?' state.sls nova.compute openstack
#   (which tends not to return...)

echo ' * Refresh pillar-data'
salt \* saltutil.refresh_pillar || exit 1


### not using any saltenv, do we salt.function??
### BUG
echo -e '\n * refresh modules and states'
salt \* saltutil.sync_all saltenv=base,openstack || exit 1

#restart minion:
#    salt.function:
#        - tgt: '*'
#        - name: cmd.run
#        - args: 'echo service salt-minion restart | at now'
#        #- require: 
#        #   - salt: refresh modules and states

echo -e '\n * configure network'
salt \* state.sls networking saltenv=openstack || exit 1
        #- require: 
        #    - salt: restart minion

echo -e '\n * install_mysql'
salt controller state.sls mysql.python saltenv=openstack || exit 1
salt -t 120 controller state.sls mysql.server saltenv=openstack || exit 1

echo -e '\n install_rabbitmq'
salt controller state.sls rabbitmq saltenv=openstack || exit 1
salt controller state.sls rabbitmq saltenv=openstack || exit 1

# saltutil.sync_modules && cmd.run 'echo service salt-minion restart' | at now

echo -e '\n install_keystone'
salt -t 120 -I roles:openstack-controller state.sls keystone saltenv=openstack || exit 1
salt -I roles:openstack-controller state.sls openstack.keystone_rc saltenv=openstack || exit 1

echo -e '\n install_nova-controller'
salt -t 120 -C I@roles:openstack-controller state.sls nova.controller saltenv=openstack || exit 1

echo -e '\n install neutron-server'
salt -t 120 controller state.sls neutron.controller saltenv=openstack || exit 1
#       - require:
#           - salt: install_mysql
#           - salt: install_rabbitmq
#           - salt: install_keystone
#       - watch:
#           - salt: install_rabbitmq

echo -e '\n install_glance'
salt controller state.sls glance saltenv=openstack || exit 1
#       - require:
#           - salt: install_keystone
#           - salt: install_rabbitmq

echo -e '\n install_horizon'
salt controller state.sls horizon saltenv=openstack || exit 1
#       - require:
#           - salt: install_keystone

echo -e '\n install_nova-compute'
salt -C I@roles:openstack-compute state.sls nova.compute saltenv=openstack || exit 1
#       - require:
#           - salt: install_nova-controller

echo -e '\n * configure openvswitch'
salt -C 'I@roles:openstack-network or I@roles:openstack-compute' \
    state.sls openvswitch saltenv=openstack || exit 1
#       - require:
#           - salt: install_nova-controller
#           - salt: configure network

echo -e '\n install neutron on network-node'
salt -C 'I@roles:openstack-network' \
    state.sls neutron.network saltenv=openstack || exit 1
#       - require: 
#           - salt: install neutron-server
#           - salt: configure openvswitch

echo -e '\n install neutron on compute-nodes'
salt -C 'I@roles:openstack-compute' \
        state.sls neutron.compute saltenv=openstack || exit 1
#       - require:
#           - salt: install neutron-server
