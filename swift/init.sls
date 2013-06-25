include:
  - swift.packages
  - swift.config
  - swift.dirs
{% if grains['id'] in pillar['swift-nodes']['storage'] %}
  - swift.devices
{% endif %}
{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
  - swift.proxy-cert
  - swift.repos
  - swift.rings
{% endif %}
