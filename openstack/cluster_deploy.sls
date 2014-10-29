install_mysql:
    salt.state:
        #This "tgt: I@..." assumes the master's
        #view on pillar!
        #- tgt: I@roles:openstack-controller
        - tgt: controller
        - sls:
            - mysql.server
            - mysql.python

install_keystone:
    salt.state:
        #- tgt: I@roles:openstack-controller
        - tgt: controller
        - sls:
            - keystone

install_nova-controller:
    salt.state:
        #- tgt: I@roles:openstack-controller
        - tgt: controller
        - sls:
            - nova.controller
