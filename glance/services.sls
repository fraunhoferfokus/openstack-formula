{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'glance/map.jinja' import glance with context %}
glance-api:
    service.running:
        - watch:
            - file: glance-api.conf
            - file: glance-api-paste.ini
        - require: 
            - file: glance-api.conf
            - file: glance-api-paste.ini
            - test: passwords for glance in pillar

glance-registry:
    service.running:
        - watch:
            - file: glance-registry.conf
            - file: glance-registry-paste.ini
        - require: 
            - file: glance-registry.conf
            - file: glance-registry-paste.ini
            - test: passwords for glance in pillar
