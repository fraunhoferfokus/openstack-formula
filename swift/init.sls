include:
  - swift.packages
  - swift.config
{% if grains['id'] in pillar['swift-nodes']['storage'] %}
  - swift.devices
  - swift.cachedir
{% endif %}
{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
  - swift.proxy-cert
  - swift.repos
{% endif %}
