{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'glance/defaults.jinja' import glance_defaults %}
{% from 'glance/map.jinja' import glance with context %}
{% if salt['pillar.get']('glance:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/glance/glance.sqlite:
    file:
      - absent
{% endif %}

{% if salt['pillar.get']('glance:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) == 'mysql' %}
    {% set db_user = salt['pillar.get'](
                    'glance:database:username',
                    salt['pillar.get'](
                        'glance:common:database:username',
                        glance_defaults.db_user)
               ) %}
    {% set db_pass = salt['pillar.get'](
                    'glance:database:password',
                    salt['pillar.get'](
                        'glance:common:database:password',
                        glance_defaults.db_pass)
               ) %}
    {% set db_host = salt['pillar.get'](
                        'glance:common:database:host', 
                        salt['pillar.get'](
                            'opestack:database:host',
                            salt['pillar.get'](
                                'openstack:controller:address_int')
                        )
                     ) %}

glance-db:
    mysql_database.present:
        - name: {{ glance_defaults.db_name }}

glance-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: '{{ db_pass }}'
        #- host: {{ db_host }}
        - host: '%'
        - require: 
            - mysql_database: glance-db

glance-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ glance_defaults.db_name }}.*
    - user: {{ db_user }}
    #- host: {{ db_host }}
    - host: '%'
    - require:
        - mysql_database: glance-db
        - mysql_user: glance-dbuser

glance-manage db_sync:
  cmd.run:
    - cwd: {{ glance.migrate_repo }}
    - name: 'glance-manage db_sync 2> /dev/null; sleep 15'
    - user: glance
    - require:
        - pkg: glance-packages
        - mysql_grants: glance-grants
    - watch:
        - pkg: glance-packages
    - listen_in:
        - service: glance-api
        - service: glance-registry
    - onlyif: test $(glance-manage db_version 2> /dev/null) -lt $(python manage.py version 2> /dev/null)
{% endif %}
