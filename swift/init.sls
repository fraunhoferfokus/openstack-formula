include:
  - swift.packages
  - swift.config
{% if grains['id'] in pillar['swift-nodes']['storage'] %}
  - swift.devices
  - swift.cachedir
{% endif %}
