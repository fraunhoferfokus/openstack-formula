{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
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
        openstack_defaults.db_type)) != 'mysql' %}

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

nova-db:
    mysql_database.present:
        - name: {{ nova_defaults.db_name }}

nova-dbuser:
    mysql_user.present:
        - name: {{ db_user }}
        - password: {{ db_pass }}

nova-grants:
    mysql_grants.present:
    - grant: all privileges
    - database: {{ nova_defaults.db_name }}.*
    - user: {{ db_user }}
    - host: {{ nova_defaults.db_host }}

{% endif %}
