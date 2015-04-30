{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
{% from 'horizon/defaults.jinja' import horizon_defaults with context %}
{% from 'horizon/map.jinja' import horizon with context %}

horizon-packages:
    pkg.installed:
        - pkgs: {{ horizon.packages }}

openstack-dashboard-ubuntu-theme:
    pkg.purged

horizon-lockdir:
    file.directory:
        - name: {{ salt['pillar.get'](
                    'horizon:lock_dir',
                    horizon_defaults.lock_dir) }}
    {#
        # not needed for '/var/run':
        - user: horizon
        - group: horizon
        - mode: 755
    #}

controllers external address known to horizon:
    test.check_pillar:
        - failhard: True
        - verbose: {{ salt['pillar.get']('horizon:verbose', False) or
                        salt['pillar.get']('horizon:debug:', False) }}
        - string: 'openstack:controller:address_ext'

local_settings.py:
    file.managed:
        - name: {{ horizon.local_settings }}
        - source: salt://horizon/files/local_settings.py
        - template: jinja
        - user: horizon
        - group: horizon
        - mode: 644
        - failhard: True
        - require:
            - pkg: horizon-packages
            - test: controllers external address known to horizon
            - file: horizon-lockdir

apache2:
    service.running:
        - watch:
            - file: local_settings.py
        - require:
            - file: local_settings.py

memcached:
    service.running:
        - watch:
            - file: local_settings.py
            - service: apache2
        - require:
            - file: local_settings.py
