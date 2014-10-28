{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'horizon/map.jinja' import horizon with context %}

horizon-packages:
    pkg.installed:
        - pkgs:
            - apache2
            - memcached
            - libapache2-mod-wsgi
            - openstack-dashboard

openstack-dashboard-ubuntu-theme:
    pkg.purged

local_settings.py:
    file.managed:
        - name: {{ horizon.local_settings }}
        - source: salt://horizon/files/local_settings.py
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: horizon-packages

apache2:
    service.running:
        - watch:
            - file: {{ horizon.local_settings }}
        - require:
            - file: {{ horizon.local_settings }}

memcached:
    service.running:
        - watch:
            - file: {{ horizon.local_settings }}
            - service: apache2
        - require:
            - file: {{ horizon.local_settings }}