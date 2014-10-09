keystone:
    pkg.installed

/etc/keystone/keystone.conf:
    file.managed:
        - source: salt://keystone/files/keystone.conf
        - template: jinja

/var/lib/keystone/keystone.db:
    file.absent