/etc/keystone/keystone.conf:
    file.managed:
        - source: salt://keystone/files/keystone.conf
        - template: jinja
