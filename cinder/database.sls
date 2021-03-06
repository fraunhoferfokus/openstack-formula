{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'cinder/defaults.jinja' import cinder_defaults %}
{% from 'cinder/map.jinja' import cinder with context %}
{% if salt['pillar.get']('cinder:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/cinder/cinder.sqlite:
    file:
      - absent

cinder-db-password-set:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('cinder:verbose', False) or
                        salt['pillar.get']('cinder:debug:', False) }}
        - string: cinder:database:password
{%- endif %}

{% if salt['pillar.get']('cinder:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) == 'mysql' %}
    {% set db_user = salt['pillar.get'](
                    'cinder:database:username',
                    cinder_defaults.db_user
               ) %}
    {% set db_pass = salt['pillar.get'](
                    'cinder:database:password',
                    cinder_defaults.db_pass
               ) %}
    {% set db_host = salt['pillar.get'](
                        'cinder:database:host', 
                        salt['pillar.get'](
                            'opestack:database:host',
                            salt['pillar.get'](
                                'openstack:controller:address_int')
                        )
                     ) %}

cinder-db:
    mysql_database.present:
        - name: {{ cinder_defaults.db_name }}
        - failhard: True
        - require:
            - test: cinder-db-password-set

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
{%- if salt['pillar.get']('cinder:debug', False) %}
    {%- set redirect = '' %}
{%- else %}
    {%- set redirect = ' 2> /dev/null' %}
{%- endif %}
    - name: 'cinder-manage db sync {{- redirect }}; sleep 15'
    - user: cinder
    - require:
        - pkg: cinder-controller-packages
        - mysql_grants: cinder-grants
        - test: cinder-db-password-set
    - watch:
        - pkg: cinder-controller-packages
    # TODO: Fix this
    #- onlyif: test $(cinder-manage db version {{ redirect }}) -lt $(python manage.py version {{ redirect }})
{# End of MySQL specific block #}
{% endif %}
