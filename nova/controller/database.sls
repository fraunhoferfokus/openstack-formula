{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'nova/defaults.jinja' import nova_defaults %}
{% from 'nova/map.jinja' import nova with context %}
{% if salt['pillar.get']('nova:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/nova/nova.sqlite:
    file:
      - absent
{% endif %}

{% if salt['pillar.get']('nova:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) == 'mysql' %}
    {% set db_user = salt['pillar.get'](
                    'nova:database:username',
                    salt['pillar.get'](
                        'nova:common:database:username',
                        nova_defaults.db_user)
               ) %}
    {% set db_pass = salt['pillar.get'](
                    'nova:database:password',
                    salt['pillar.get'](
                        'nova:common:database:password',
                        nova_defaults.db_pass)
               ) %}
    {% set db_host = salt['pillar.get'](
                        'nova:common:database:host', 
                        salt['pillar.get'](
                            'opestack:database:host',
                            salt['pillar.get'](
                                'openstack:controller:address_int')
                        )
                     ) %}

nova-db:
    mysql_database.present:
        - name: {{ nova_defaults.db_name }}

nova-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: '{{ db_pass }}'
        #- host: {{ db_host }}
        - host: '%'
        - require: 
            - mysql_database: nova-db

nova-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ nova_defaults.db_name }}.*
    - user: {{ db_user }}
    #- host: {{ db_host }}
    - host: '%'
    - require:
        - mysql_database: nova-db
        - mysql_user: nova-dbuser

nova-manage db sync:
  cmd.run:
    - cwd: {{ nova.migrate_repo }}
    - name: 'nova-manage db sync; sleep 15'
    - user: nova
    - require:
        - pkg: nova-controller-packages
        - mysql_grants: nova-grants
    - watch:
        - pkg: nova-controller-packages
    - onlyif: test $(nova-manage db version) -lt $(python manage.py version)
{% endif %}
