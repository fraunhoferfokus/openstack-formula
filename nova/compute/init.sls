{% from 'nova/map.jinja' import nova with context %}

nova-compute:
    pkg.installed:
        - names: {{ nova.compute_packages }}
    service.running:
        - require:
            - pkg: nova-compute
            - file: {{ nova.nova_conf_file }}
        - watch:
            - file: {{ nova.nova_conf_file }}

include:
    - nova.nova_conf
