{% from 'keystone/defaults.jinja' import keystone_defaults %}
keystone:
    pkg:
        - installed
    service.running:
        - require:
            - pkg: keystone
            - file: /etc/keystone/keystone.conf 
            - mysql_database: keystone-db

/etc/keystone/keystone.conf:
    file.managed:
        - source: salt://keystone/files/keystone.conf
        - template: jinja
        - require:
            - pkg: keystone

{% set db_user = salt['pillar.get'](
                    'keystone:database:username', 
                    salt['pillar.get'](
                        'keystone:common:database:username',
                        keystone_defaults.db_user)
               ) %}
{% set db_pass = salt['pillar.get'](
                    'keystone:database:password', 
                    salt['pillar.get'](
                        'keystone:common:database:password',
                        keystone_defaults.db_pass)
               ) %}

keystone-db:
    mysql_database.present:
        - name: {{ keystone_defaults.db_name }}

keystone-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: {{ db_pass }}

keystone-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ keystone_defaults.db_name }}.*
    - user: {{ db_user }}
    - host: {{ keystone_defaults.db_host }}

{% if salt['pillar.get'](
        'keystone:database:type', 
        keystone_defaults.db_type) != 'sqlite' %}
/var/lib/keystone/keystone.db:
    file.absent
{% endif %}
