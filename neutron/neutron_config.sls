{% from 'neutron/map.jinja' import neutron with context %}
neutron.conf:
    file.managed:
        - name: {{ neutron.conf_dir}}/neutron.conf
        - user: root
        - group: neutron
        - mode: 640
        - source: salt://neutron/files/neutron.conf
        - template: jinja
        #- require:
        #    - pkg: neutron-server
