{% from 'pkgrepo/map.jinja' import openstack with context %}
{% set os_release = salt['pillar.get']('openstack:release') %}
{% if grains.os_family == 'Ubuntu' %}
  {% if openstack.release != os_release %}
cloud-archive/{{ release }}:
    pkgrepo.managed:
        name: 
        name: deb-src {{ openstack.repo_url }} {{ grains.oscodename }}-updates/{{ os_release }} main
        file: /etc/apt/sources.list.d/cloudarchive-{{ os_release }}.list

cloud-archive/{{ release }} (src):
    pkgrepo.managed:
        name: deb-src {{ openstack.repo_url }} {{ 
            grains.oscodename }}-updates/{{ os_release }} main
        file: /etc/apt/sources.list.d/cloudarchive-{{ os_release }}.list
  {% endif %}
{% endif %}
