{% from 'openstack/defaults.jinja' import openstack_defaults %}
{% from 'keystone/defaults.jinja' import keystone_defaults %}
keystone-package:
    pkg.installed:
      - name: keystone

keystone.conf:
    file.managed:
        - name: /etc/keystone/keystone.conf
        - source: salt://keystone/files/keystone.conf
        - template: jinja
        - require:
            - pkg: keystone-package

keystone passwords in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('keystone:verbose', False) or
                        salt['pillar.get']('keystone:debug:', False) }}
        - string: 
            - keystone:database:password
            - keystone:admin_password

{% set db_user = salt['pillar.get'](
                    'keystone:database:username', 
                    keystone_defaults.db_user
               ) %}
{% set db_pass = salt['pillar.get'](
                    'keystone:database:password', 
                    keystone_defaults.db_pass
               ) %}
{% set db_hash = salt['pillar.get'](
                    'keystone:database:password_hash', None) %}
{% set db_host = salt['pillar.get'](
                    'keystone:database:host', 
                    salt['pillar.get'](
                        'openstack:database:host',
                        salt['pillar.get'](
                            'openstack:controller:address_int',
                            keystone_defaults.db_host)
                    )
                 ) %}

keystone-db:
    mysql_database.present:
        - name: {{ keystone_defaults.db_name }}
        - failhard: True
{% if 'test.check_pillar' in salt['sys.list_state_functions']() %}
        - require:
            - test: keystone passwords in pillar
{% endif %}

keystone-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
{% if db_hash is not none  %}    
        - password_hash: '{{ db_hash }}'
{% else %}
        - password: '{{ db_pass }}'
{% endif %}
        - host: '%'
        #- host: {{ db_host }}

keystone-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ keystone_defaults.db_name }}.*
    - user: {{ db_user }}
    - host: '%'
    #- host:{{ db_host }}
    - require:
        #- mysql_user: keystone-dbuser
        - mysql_database: keystone-db

{% if salt['pillar.get'](
        'keystone:database:type', 
        keystone_defaults.db_type) != 'sqlite' %}
/var/lib/keystone/keystone.db:
    file.absent
{% endif %}

keystone-manage db_sync:
  cmd.run:
    - name: 'keystone-manage db_sync 2> /dev/null; sleep 15'
    - user: keystone
    # TODO: This path shouldn't be Ubuntu-specific!
    - cwd:  /usr/lib/python2.7/dist-packages/keystone/common/sql/migrate_repo/
    - failhard: True
    - require:
        - pkg: keystone-package
        - mysql_grants: keystone-grants
        - file: keystone.conf
{% if 'test.check_pillar' in salt['sys.list_state_functions']() %}
        - test: keystone passwords in pillar
{% endif %}
    - watch:
        - pkg: keystone-package
    - onlyif: test $(keystone-manage db_version 2> /dev/null) -lt $( python manage.py version . 2> /dev/null)

keystone-service:
    service.running:
        - name: keystone
        - failhard: True
        - require:
            - pkg: keystone-package
            - file: keystone.conf 
            - cmd: keystone-manage db_sync
        - watch:
            - pkg: keystone-package
            - file: keystone.conf 
            - mysql_user: keystone-dbuser
            - cmd: keystone-manage db_sync

create basic tenants in Keystone:
  keystone.tenant_present:
    - names:
      - admin
      - service
    - require:
      - cmd: keystone-manage db_sync
      - service: keystone-service
    - listen: 
      - cmd: keystone-manage db_sync

create basic roles in Keystone:
  keystone.role_present:
    - names:
      - admin
      - Member
      # Why do we need the following two??
      - KeystoneAdmin
      - KeystoneServiceAdmin
    - require:
      - cmd: keystone-manage db_sync
      - service: keystone-service
    - listen: 
      - cmd: keystone-manage db_sync

create admin-user in Keystone:
  keystone.user_present:
    - name: admin
    - password: {{ salt['pillar.get']('keystone:admin_password',
                    keystone_defaults.admin_password) }}
    - email: {{ salt['pillar.get']('keystone:admin_email',
                    keystone_defaults.admin_email) }}
    - roles:
        admin:   # tenants
          - admin  # roles
          - KeystoneAdmin
          - KeystoneServiceAdmin
        service:
          - admin
          - Member
    - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
    - require:
{% if 'test.check_pillar' in salt['sys.list_state_functions']() %}
      - test: keystone passwords in pillar
{% endif %}
      - service: keystone-service
      - keystone: create basic tenants in Keystone
      - keystone: create basic roles in Keystone
    - listen: 
      - cmd: keystone-manage db_sync

keystone-service in Keystone:
    keystone.service_present:
        - name: keystone
        - service_type: identity
        - description: OpenStack Identity Service
        - require:
            - service: keystone-service
        - listen: 
          - cmd: keystone-manage db_sync

keystone-endpoint in Keystone:
    keystone.endpoint_present:
        - name: keystone
        - publicurl: {{ "{0}://{1}:{2}/v2.0".format(
                salt['pillar.get'](
                    'openstack:keystone:auth_protocol', 
                    'http'),
                salt['pillar.get'](
                    'openstack:controller:address_ext',
                    '127.0.0.1'),
                salt['pillar.get'](
                    'openstack:keystone:public_port', 
                    5000)
                ) }}
        - adminurl: {{ "{0}://{1}:{2}/v2.0".format(
                salt['pillar.get'](
                    'openstack:keystone:auth_protocol', 
                    'http'),
                salt['pillar.get'](
                    'openstack:controller:address_int', 
                    '127.0.0.1'),
                salt['pillar.get'](
                    'openstack:keystone:auth_port', 
                    35357)
                ) }}
        - internalurl: {{ "{0}://{1}:{2}/v2.0".format(
                salt['pillar.get'](
                    'openstack:keystone:auth_protocol', 
                    'http'),
                salt['pillar.get'](
                    'openstack:controller:address_int', 
                    '127.0.0.1'),
                salt['pillar.get'](
                    'openstack:keystone:public_port', 
                    5000)
                ) }}
        - region: {{ salt['pillar.get']('keystone.region',
                    salt['pillar.get']('openstack:region_name',
                        openstack_defaults.region_name)
                 ) }}
        - require:
            - cmd: keystone-manage db_sync
            - keystone: keystone-service in Keystone
        - listen: 
          - cmd: keystone-manage db_sync

{% if salt['pillar.get']('keystone:keystone_rc:enable', True) %}
keystone_rc:
    file.managed:
        - name: {{ 
            salt['pillar.get'](
                'keystone:keystone_rc:path',
                '/root/keystone.rc') }}
        - source: salt://keystone/files/keystone.rc
        - template: jinja
        - user: root
        - group: root
        - mode: 400
{% endif %}
