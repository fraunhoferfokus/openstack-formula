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

local_settings.py:
    file.managed:
        - name: {{ horizon.local_settings }}
        - source: salt://horizon/files/local_settings.py
        - template: jinja
        - user: horizon
        - group: horizon
        - mode: 644
        - require:
            - pkg: horizon-packages
            - file: horizon-lockdir

apache2:
    service.running:
        - listen:
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
