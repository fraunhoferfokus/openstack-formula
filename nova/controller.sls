{% from 'openstack/defaults.jinja' import openstack_defaults with context %}
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

{% if salt['pillar.get']('nova:common:database:type', 
    salt['pillar.get']('openstack:db_type', 
        openstack_defaults.db_type)) != 'sqlite' %}
/var/lib/nova/nova.sqlite:
    file:
      - absent
{% endif %}
