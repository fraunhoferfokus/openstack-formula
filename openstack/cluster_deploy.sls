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

refresh pillar:
    salt.function:
        - name: saltutil.refresh_pillar
        - tgt: '*'

### not using any saltenv, do we salt.function??
### BUG
refresh modules and states:
    salt.function:
        - name: saltutil.sync_all
        - tgt: '*'
        - arg:
           - saltenv: openstack

#restart minion:
#    salt.function:
#        - tgt: '*'
#        - name: cmd.run
#        - args: 'echo service salt-minion restart | at now'
#        #- require: 
#        #   - salt: refresh modules and states

configure network:
    salt.state:
        - tgt: '*'
        - sls:
            - networking
        #- require: 
        #    - salt: restart minion

install_mysql:
    salt.state:
        - tgt: 'controller'
        - sls:
            - mysql.server
            - mysql.python

install_rabbitmq:
    salt.state:
        - tgt: 'controller*'
        - sls:
            - rabbitmq

# saltutil.sync_modules && cmd.run 'echo service salt-minion restart' | at now

install_keystone:
    salt.state:
        #- tgt: I@roles:openstack-controller
        - tgt: 'controller*'
        - sls:
            - keystone
            - openstack.keystone_rc
        - require:
            - salt: install_mysql
            - salt: install_rabbitmq

install_nova-controller:
    salt.state:
        - tgt: I@roles:openstack-controller
        - tgt_type: pillar
        - sls:
            - nova.controller
        - require:
            - salt: install_mysql
            - salt: install_rabbitmq
            - salt: install_keystone

install neutron-server:
    salt.state:
        - tgt: controller
        - sls:
            - neutron.controller
        - require:
            - salt: install_mysql
            - salt: install_rabbitmq
            - salt: install_keystone
        - watch:
            - salt: install_rabbitmq

install_glance:
    salt.state:
        - tgt: controller
        - sls:
            - glance
        - require:
            - salt: install_keystone
            - salt: install_rabbitmq

install_horizon:
    salt.state:
        - tgt: controller
        - sls:
            - horizon
        - require:
            - salt: install_keystone

install_nova-compute:
    salt.state:
        - tgt: I@roles:openstack-compute
        - tgt_type: pillar
        - sls:
            - nova.compute
        - require:
            - salt: install_nova-controller

configure openvswitch:
    salt.state:
        # TODO - needs to be changed:
        - tgt: '*'
            # compute nodes
            # network node
        - sls:
            - openvswitch
        - require:
            - salt: install_nova-controller
            - salt: configure network

install neutron on network-node:
    salt.state:
        - tgt: controller
        - sls: neutron.network
        - require: 
            - salt: install neutron-server
            - salt: configure openvswitch

install neutron on compute-nodes:
    salt.state:
        - tgt: 'compute-[12]'
        - tgt_type: regexp
        - sls: neutron.compute
        - require:
            - salt: install neutron-server
