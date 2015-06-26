{% from 'cinder/map.jinja' import cinder with context -%}
{% from 'cinder/defaults.jinja' import cinder_defaults with context -%}

cinder passwords in pillar:
    test.check_pillar:
        - failhard: True
        - verbose:  {{ salt['pillar.get']('cinder:verbose', False) or
                        salt['pillar.get']('cinder:debug:', False) }}
        - string:
            - cinder:keystone_authtoken:admin_password

cinder.conf:
    file.managed:
        - name: {{ cinder.conf_dir }}/cinder.conf
        - source:
            - salt://cinder/files/cinder.conf_
            {{- salt['pillar.get']('openstack:release') }}
            - salt://cinder/files/cinder.conf
        - template: jinja
        - user: cinder
        - group: cinder
        - failhard: True
        - require:
            - test: cinder passwords in pillar
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
        - source:
            - salt://cinder/files/nfsshares_
            {{- salt['pillar.get']('openstack:release') }}
            - salt://cinder/files/nfsshares
        - template: jinja
        - user: root
        - group: cinder
        - mode: 640
        - require:
            - pkg: nfs-client-for-cinder
  {% endif %}
{% endif %}

