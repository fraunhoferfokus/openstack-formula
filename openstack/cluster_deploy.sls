install_mysql:
    salt.state:
        - tgt: I@roles:openstack-controller
        - sls:
            - mysql.server
            - mysql.python

install_keystone:
    salt.state:
        - tgt: I@roles:openstack-controller
        - sls:
            - keystone

install_nova-controller:
    salt.state:
        - tgt: I@roles:openstack-controller
        - sls:
            - nova.controller
