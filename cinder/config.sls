{% from 'cinder/map.jinja' import cinder with context -%}
{% from 'cinder/defaults.jinja' import cinder_defaults with context -%}
cinder.conf:
    file.managed:
        - name: {{ cinder.conf_dir }}/cinder.conf
        - source: salt://cinder/files/cinder.conf
        - template: jinja
        - user: cinder
        - group: cinder
        - require:
{% if 'cinder-controller' in salt['pillar.get']('roles',[]) %}
            - pkg: cinder-controller-packages
{% endif %}
{% if 'cinder-node' in salt['pillar.get']('roles',[]) %}
            - pkg: cinder-node-packages

  {% if 'cinder.volume.drivers.nfs.NfsDriver' == salt['pillar.get'](
        'cinder:volume_driver', cinder_defaults.volume_driver) %}
nfsshares:
    file.managed:
        - name: {{ cinder.conf_dir }}/nfsshares
        - source: salt://cinder/files/nfsshares
        - template: jinja
        - user: root
        - group: cinder
        - mode: 640
        - require:
            - pkg: nfs-client-for-cinder
  {% endif %}
{% endif %}

