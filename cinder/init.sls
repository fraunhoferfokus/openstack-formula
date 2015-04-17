#!jinja|yamlex
{%- from 'cinder/map.jinja' import cinder with context %}
{% if 'cinder-controller' in salt['pillar.get']('roles',[]) %}
include: !aggregate
    - cinder.database
    - cinder.keystone
    - cinder.controller
{% endif %}
{% if 'cinder-node' in salt['pillar.get']('roles',[]) %}
include: !aggregate
    - cinder.node
{% endif %}

