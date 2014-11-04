{% from 'nova/map.jinja' import nova with context %}

nova-compute:
    pkg.installed:
        - names: {{ nova.compute_packages }}
    service.running:
        - require:
            - pkg: nova-compute
            - file: nova.conf
        - watch:
            - file: nova.conf

nova.conf:
    file.managed:
        - name: {{ nova.nova_conf_file }}
        - source: salt://nova/files/nova.conf_compute
        - template: jinja
        - user: nova
        - group: nova
        - mode: 640
