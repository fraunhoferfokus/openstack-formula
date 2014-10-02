glance-api.conf:
    file.managed:
        - name: /etc/glance/glance-api.conf
        - source: salt://glance/files/glance-api.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

glance-api-paste.ini:
    file.managed:
        - name: /etc/glance/glance-api-paste.ini
        - source: salt://glance/files/glance-api-paste.ini
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

glance-cache.conf:
    file.managed:
        - name: /etc/glance/glance-cache.conf
        - source: salt://glance/files/glance-cache.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

glance-registry.conf:
    file.managed:
        - name: /etc/glance/glance-registry.conf
        - source: salt://glance/files/glance-registry.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

glance-registry-paste.ini:
    file.managed:
        - name: /etc/glance/glance-registry-paste.ini
        - source: salt://glance/files/glance-registry-paste.ini
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

glance-scrubber.conf:
    file.managed:
        - name: /etc/glance/glance-scrubber.conf
        - source: salt://glance/files/glance-scrubber.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

policy.json:
    file.managed:
        - name: /etc/glance/policy.json
        - source: salt://glance/files/policy.json
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

schema-image.json:
    file.managed:
        - name: /etc/glance/schema-image.json
        - source: salt://glance/files/schema-image.json
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644

