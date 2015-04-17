#!jinja|yamlex
{% from 'cinder/map.jinja' import cinder with context %}
{% from 'cinder/defaults.jinja' import cinder_defaults %}
{# from 'openstack/defaults.jinja' import openstack_defaults #}
include: !aggregate cinder.config

cinder-node-packages:
    pkg.installed:
        - names: {{ cinder.node_pkgs }}

cinder-volume:
    service.running:
        - require:
            - file: cinder.conf
            - pkg: cinder-node-packages
{%- if 'cinder.volume.drivers.lvm.LVMISCSIDriver' == salt['pillar.get'](
    'cinder:volume_driver', cinder_defaults.volume_driver) %}
            - pkg: lvm2-for-cinder
    
lvm2-for-cinder:
    pkg.installed:
        - name: lvm2

{% elif 'cinder.volume.drivers.nfs.NfsDriver' == salt['pillar.get'](
        'cinder:volume_driver', cinder_defaults.volume_driver) -%}
  {# Just in case this state is run on OS with built-in NFS-Client: #}
  {%- if cinder.nfs_pkg %}
            - pkg: nfs-client-for-cinder
    
nfs-client-for-cinder:
    pkg.installed:
        - name: {{ cinder.nfs_pkg }}
  {%- endif %}
{%- endif %}
