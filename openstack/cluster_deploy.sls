install_mysql:
    salt.state:
        #This "tgt: I@..." assumes the master's
        #view on pillar!
        #- tgt: I@roles:openstack-controller
        - tgt: controller
        - sls:
            - mysql.server
            - mysql.python

install_rabbitmq:
    salt.state:
        - tgt: controller
        - sls:
            - rabbitmq

# saltutil.sync_modules && cmd.run 'echo service salt-minion restart' | at now

install_keystone:
    salt.state:
        #- tgt: I@roles:openstack-controller
        - tgt: controller
        - sls:
            - keystone
            - openstack.keystone_rc
        - require:
            - salt: install_mysql
            #- salt: install_rabbitmq

install_nova-controller:
    salt.state:
        #- tgt: I@roles:openstack-controller
        - tgt: controller
        - sls:
            - nova.controller
        - require:
            - salt: install_mysql
            - salt: install_rabbitmq
            - salt: install_keystone

install_neutron-server:
    salt.state:
        - tgt: controller
        - sls:
            - neutron.server
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
