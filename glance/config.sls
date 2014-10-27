{% from 'glance/map.jinja' import glance with context %}
glance-api.conf:
    file.managed:
        - name: {{ glance.api_conf_file }}
        - source: salt://glance/files/glance-api.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

glance-api-paste.ini:
    file.managed:
        - name: {{ glance.api_paste_ini }}
        - source: salt://glance/files/glance-api-paste.ini
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

glance-cache.conf:
    file.managed:
        - name: {{ glance.cache_conf_file }}
        - source: salt://glance/files/glance-cache.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

glance-registry.conf:
    file.managed:
        - name: {{ glance.registry_conf_file }}
        - source: salt://glance/files/glance-registry.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

glance-registry-paste.ini:
    file.managed:
        - name: {{ glance.registry_paste_ini }}
        - source: salt://glance/files/glance-registry-paste.ini
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

glance-scrubber.conf:
    file.managed:
        - name: {{ glance.scrubber_conf_file }}
        - source: salt://glance/files/glance-scrubber.conf
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

policy.json:
    file.managed:
        - name: {{ glance.policy_json_file }}
        - source: salt://glance/files/policy.json
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

schema-image.json:
    file.managed:
        - name: {{ glance.schema_image_json_file }}
        - source: salt://glance/files/schema-image.json
        - template: jinja
        - user: glance
        - group: glance
        - mode: 644
        - require:
            - pkg: glance-packages

