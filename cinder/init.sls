#!jinja|yaml
{% from 'cinder/map.jinja' import cinder with context %}
include:
    - cinder.database

cinder-packages:
    pkg.installed:
        - names: {{ cinder.packages }}

cinder.conf:
    file.managed:
        - name: {{ cinder.conf_dir }}/cinder.conf
        - source: salt://cinder/files/cinder.conf
        - template: jinja
        - user: cinder
        - group: cinder
        - require:
            - pkg: cinder-packages

cinder-scheduler:
    service.running:
        - require:
            - file: cinder.conf

cinder-api:
    service.running:
        - watch:
            - file: cinder.conf
        - require:
            - file: cinder.conf

