{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'heat/defaults.jinja' import heat_defaults %}
{% from 'heat/map.jinja' import heat with context %}
{% if salt['pillar.get']('heat:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/heat/heat.sqlite:
    file:
      - absent

database password for heat in pillar:
    test.check_pillar:
        - string: 'heat:database:password'
{% endif %}
{% if salt['pillar.get']('heat:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) == 'mysql' %}
    {% set db_user = salt['pillar.get'](
                    'heat:database:username',
                    salt['pillar.get'](
                        'heat:common:database:username',
                        heat_defaults.db_user)
               ) %}
    {% set db_pass = salt['pillar.get'](
                    'heat:database:password',
                    salt['pillar.get'](
                        'heat:common:database:password',
                        heat_defaults.db_pass)
               ) %}
    {% set db_host = salt['pillar.get'](
                        'heat:common:database:host', 
                        salt['pillar.get'](
                            'opestack:database:host',
                            salt['pillar.get'](
                                'openstack:controller:address_int')
                        )
                     ) %}

heat-db:
    mysql_database.present:
        - name: {{ heat_defaults.db_name }}
        - failhard: True
        - require:
            - test: database password for heat in pillar

heat-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: '{{ db_pass }}'
        #- host: {{ db_host }}
        - host: '%'
        - require: 
            - mysql_database: heat-db

heat-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ heat_defaults.db_name }}.*
    - user: {{ db_user }}
    #- host: {{ db_host }}
    - host: '%'
    - require:
        - mysql_database: heat-db
        - mysql_user: heat-dbuser

heat-manage db_sync:
  cmd.run:
{% if salt['pillar.get']('heat:debug', False) %}
    {%- set redirect = '' %}
{% else %}
    {%- set redirect = ' 2> /dev/null' %}
{%- endif %}
    - name: 'heat-manage db_sync {{- redirect }}; sleep 15'
    - user: heat
    - require:
        - pkg: heat-packages
        - mysql_grants: heat-grants
    - watch:
        - pkg: heat-packages
    - failhard: True
    - require:
        - test: database password for heat in pillar
{% endif %}
