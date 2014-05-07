include:
  - swift.packages
  - swift.config
  - swift.dirs
{% if grains.get('id') in pillar.get('swift:nodes:storage',[]) %}
  - swift.devices
  - swift.storage-services
{% endif %}
{% if grains.get('id') in pillar.get('swift:nodes:proxy',[]) %}
  - swift.proxy-cert
  - swift.repos
  - swift.rings
  - swift.proxy-services
{% endif %}
