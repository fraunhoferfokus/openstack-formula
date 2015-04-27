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
        - string:
            - neutron:keystone_authtoken:admin_password
            - neutron:database:password
            - openstack:rabbitmq:password 
        
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
