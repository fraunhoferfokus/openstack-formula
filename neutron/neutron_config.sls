{% from 'neutron/map.jinja' import neutron with context %}
{{ neutron.conf_dir }}:
    file.directory:
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 750
{% else %}
        - mode: 755
{% endif %}
        - makedirs: True
        
neutron.conf:
    file.managed:
        - name: {{ neutron.conf_dir}}/neutron.conf
        - user: root
{% if salt['group.info']('neutron') %}
        - group: neutron
        - mode: 640
{% else %}
        - mode: 644
{% endif %}
        - source: salt://neutron/files/neutron.conf
        - template: jinja
        #- require:
        #    - pkg: neutron-server
