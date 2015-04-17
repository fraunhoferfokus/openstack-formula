#!jinja|yamlex
{% from 'cinder/map.jinja' import cinder with context %}
{# from 'cinder/defaults.jinja' import cinder_defaults #}
{# from 'openstack/defaults.jinja' import openstack_defaults #}

include: !aggregate cinder.config
include: !aggregate cinder.database

cinder-controller-packages:
    pkg.installed:
        - names: {{ cinder.controller_pkgs }}

cinder-scheduler:
    service.running:
        - require:
            - file: cinder.conf
            - cmd: cinder-manage db sync

cinder-api:
    service.running:
        - watch:
            - file: cinder.conf
            - cmd: cinder-manage db sync
        - require:
            - file: cinder.conf
            - cmd: cinder-manage db sync
