{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'neutron/defaults.jinja' import neutron_defaults %}
{% from 'neutron/map.jinja' import neutron with context %}
{% if salt['pillar.get']('neutron:common:database:type',
    salt['pillar.get']('openstack:db_type',
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/neutron/neutron.sqlite:
    file:
      - absent
{% endif %}

{% if salt['pillar.get']('neutron:common:database:type',
    salt['pillar.get']('openstack:db_type',
        openstack_defaults.db_type)) == 'mysql' %}
    {% set db_user = salt['pillar.get'](
                    'neutron:database:username',
                    salt['pillar.get'](
                        'neutron:common:database:username',
                        neutron_defaults.db_user)
               ) %}
    {% set db_pass = salt['pillar.get'](
                    'neutron:database:password',
                    salt['pillar.get'](
                        'neutron:common:database:password',
                        neutron_defaults.db_pass)
               ) %}
    {% set db_host = salt['pillar.get'](
                        'neutron:common:database:host',
                        salt['pillar.get'](
                            'opestack:database:host',
                            salt['pillar.get'](
                                'openstack:controller:address_int')
                        )
                     ) %}

neutron-db:
    mysql_database.present:
        - name: {{ neutron_defaults.db_name }}

neutron-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: '{{ db_pass }}'
        #- host: {{ db_host }}
        - host: '%'
        - require:
            - mysql_database: neutron-db

neutron-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ neutron_defaults.db_name }}.*
    - user: {{ db_user }}
    #- host: {{ db_host }}
    - host: '%'
    - require:
        - mysql_database: neutron-db
        - mysql_user: neutron-dbuser
{% endif %}

{# this tools just stacktraces anyway...
neutron-db-manage upgrade:
    cmd.run:
        # That's a rather wild guess but whatever...
        - onlyif: test $(neutron-db-manage current) -lt $(neutron-db-manage revision)
        - require: 
            - mysql_grants: neutron-grants
#}
