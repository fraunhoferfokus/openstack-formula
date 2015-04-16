{% from 'cinder/map.jinja' import cinder with context %}

Cinder packages:
    pkg.installed:
        - names: {{ cinder.packages }}

{{ cinder.conf_dir }}/cinder.conf:
    file.managed:
        - source: salt://cinder/files/cinder.conf
        - template: jinja
        - user: cinder
        - group: cinder
        - require:
            - pkg: Cinder packages

cinder-api:
    service.running:
        - require:
            - pkg: Cinder packages
            - file: {{ cinder.conf_dir }}/cinder.conf

cinder-scheduler:
    service.running:
        - require:
            - pkg: Cinder packages
            - file: {{ cinder.conf_dir }}/cinder.conf
