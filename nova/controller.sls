{% from 'nova/map.jinja' import nova with context %}
nova-controller-packages:
  pkg.installed:
    - names: {{ nova.controller_packages }}
