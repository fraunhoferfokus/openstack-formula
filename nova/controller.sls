{% from 'nova/map.jinja' import nova with context %}
nova-controller-packages:
  pkg.installed:
    - names: {{ nova.controller_packages }}

/etc/nova/nova.conf:
    file.managed:
      - user: nova
      - mode: 640
      - source: salt://nova/files/nova.conf
      - template: jinja

{% if salt['pillar.get']('nova:
