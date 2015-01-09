{% from 'neutron/map.jinja' import neutron with context %}
ml2_conf.ini:
    file.managed:
        - name: {{ neutron.conf_dir }}/plugins/ml2/ml2_conf.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/ml2_conf.ini
        - template: jinja
        #- require:
        #    - pkg: neutron-server
