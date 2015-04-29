{% from 'neutron/map.jinja' import neutron with context %}
{{ neutron.conf_dir }}:
    file.directory:
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 750
{% else %}
        - mode: 755
{% endif %}
        - makedirs: True

neutron passwords in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: True
        - string:
{%- if not salt['pillar.get']('neutron.password', False) %}
            - neutron:keystone_authtoken:admin_password
{% else %}
            - neutron.password
{%- endif %}
{#- Only the neutron-server needs the db credentials #}
{%- if 'openstack-controller' in pillar.get('roles', []) %}
            - neutron:database:password
{%- endif %}
            - openstack:rabbitmq:password 

nova-credentials for Neutron in pillar:
    test.check_pillar:
        - failhard: True
        - verbose: True
        - string: 
{% if not salt['pillar.get'](
    'nova:keystone_authtoken:admin_password', False) %}
            - neutron:nova_admin_password
{% elif salt['pillar.get']('keystone.user') == 'nova' and
    salt['pillar.get']('keystone.password', False) is string %}
            - keystone.password
{% else %}
            - nova:keystone_authtoken:admin_password
{% endif %}
        
neutron.conf:
    file.managed:
        - name: {{ neutron.conf_dir}}/neutron.conf
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 640
{% else %}
        - mode: 644
{% endif %}
        - source: salt://neutron/files/neutron.conf
        - template: jinja
        - failhard: True
        - require:
            - test: neutron passwords in pillar
        #   - pkg: neutron-server
