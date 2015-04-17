{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'cinder/defaults.jinja' import cinder_defaults %}
{% from 'cinder/map.jinja' import cinder with context %}
{% if salt['pillar.get']('cinder:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/cinder/cinder.sqlite:
    file:
      - absent
{% endif %}

{% if salt['pillar.get']('cinder:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) == 'mysql' %}
    {% set db_user = salt['pillar.get'](
                    'cinder:database:username',
                    salt['pillar.get'](
                        'cinder:common:database:username',
                        cinder_defaults.db_user)
               ) %}
    {% set db_pass = salt['pillar.get'](
                    'cinder:database:password',
                    salt['pillar.get'](
                        'cinder:common:database:password',
                        cinder_defaults.db_pass)
               ) %}
    {% set db_host = salt['pillar.get'](
                        'cinder:common:database:host', 
                        salt['pillar.get'](
                            'opestack:database:host',
                            salt['pillar.get'](
                                'openstack:controller:address_int')
                        )
                     ) %}

cinder-db:
    mysql_database.present:
        - name: {{ cinder_defaults.db_name }}

cinder-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: '{{ db_pass }}'
        #- host: {{ db_host }}
        - host: '%'
        - require: 
            - mysql_database: cinder-db

cinder-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ cinder_defaults.db_name }}.*
    - user: {{ db_user }}
    #- host: {{ db_host }}
    - host: '%'
    - require:
        - mysql_database: cinder-db
        - mysql_user: cinder-dbuser

cinder-manage db sync:
  cmd.run:
    - cwd: {{ cinder.migrate_repo }}
    - name: 'cinder-manage db sync 2> /dev/null; sleep 15'
    - user: cinder
    - require:
        - pkg: cinder-controller-packages
        - mysql_grants: cinder-grants
    - watch:
        - pkg: cinder-controller-packages
    - onlyif: test $(cinder-manage db version 2> /dev/null) -lt $(python manage.py version 2> /dev/null)
{% endif %}
