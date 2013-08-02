include:
  - swift.packages
  - swift.config
  - swift.dirs
{% if grains['id'] in pillar['swift-nodes']['storage'] %}
  - swift.devices
  - swift.storage-services
{% endif %}
{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
  - swift.proxy-cert
  - swift.repos
  - swift.rings
  - swift.proxy-services
{% endif %}
