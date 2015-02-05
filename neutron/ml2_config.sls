{% from 'neutron/map.jinja' import neutron with context %}
{{ neutron.conf_dir }}/plugins/ml2:
    file.directory:
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 750
{% else %}
        - mode: 755
{% endif %}
        - makedirs: True

ml2_conf.ini:
    file.managed:
        - name: {{ neutron.conf_dir }}/plugins/ml2/ml2_conf.ini
        - user: neutron
        - mode: 640
        - source: salt://neutron/files/ml2_conf.ini
        - template: jinja
        - require:
            - pkg: neutron-common

neutron-common:
    pkg.installed
