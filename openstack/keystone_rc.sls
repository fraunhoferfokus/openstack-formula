keystone_rc:
    file.managed:
        - name: {{ 
            salt['pillar.get'](
                'openstack:keystone_rc:path',
                '/root/keystone.rc') }}
        - source: salt://openstack/files/keystone.rc
        - template: jinja
        - user: root
        - group: root
        - mode: 400
