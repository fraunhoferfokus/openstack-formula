include:
  - swift.packages
  - swift.config
  - swift.dirs
{% if grains['id'] in pillar.get('swift:nodes:storage,[]).items() %}
  - swift.devices
  - swift.storage-services
{% endif %}
{% if grains['id'] in pillar.get('swift:nodes:proxy',[]).items() %}
  - swift.proxy-cert
  - swift.repos
  - swift.rings
  - swift.proxy-services
{% endif %}
