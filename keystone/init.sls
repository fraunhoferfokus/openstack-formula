{% from 'keystone/defaults.jinja' import keystone_defaults %}
keystone:
    pkg:
        - installed
    service.running:
        - require:
            - pkg: keystone
            - file: /etc/keystone/keystone.conf 
            - mysql_database: keystone-db
        - watch:
            - pkg: keystone
            - file: /etc/keystone/keystone.conf 
            - cmd: keystone-manage db_sync

/etc/keystone/keystone.conf:
    file.managed:
        - source: salt://keystone/files/keystone.conf
        - template: jinja
        - require:
            - pkg: keystone

{% set db_user = salt['pillar.get'](
                    'keystone:database:username', 
                    salt['pillar.get'](
                        'keystone:database:username',
                        keystone_defaults.db_user)
               ) %}
{% set db_pass = salt['pillar.get'](
                    'keystone:database:password', 
                    salt['pillar.get'](
                        'keystone:database:password',
                        keystone_defaults.db_pass)
               ) %}
{% set db_hash = salt['pillar.get'](
                    'keystone:database:password_hash', None) %}
{% set db_host = salt['pillar.get'](
                    'keystone:database:host', 
                    salt['pillar.get'](
                        'openstack:database:host',
                        salt['pillar.get'](
                            'openstack:controller_address',
                            keystone_defaults.db_host)
                    )
                 ) %}

keystone-db:
    mysql_database.present:
        - name: {{ keystone_defaults.db_name }}

## Broken due to https://github.com/saltstack/salt/issues/16676
## (TODO: uncomment require in keystone-grants when this is fixed)
#keystone-dbuser:
#    mysql_user.present:
#        - name: {{ db_user }}
#{% if db_hash is not none  %}    
#        - password_hash: '{{ db_hash }}'
#{% else %}
#        - password: '{{ db_pass }}'
#{% endif %}
#        - host: '%'
#        #- host: {{ db_host }}

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
    - user: keystone
    - require:
        - pkg: keystone
        #- mysql_grants: keystone-grants @controller
        - mysql_grants: keystone-grants
    - watch:
        - pkg: keystone
