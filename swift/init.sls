include:
  - swift.packages
  - swift.config
  - swift.dirs
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:storage',[]) %}
  - swift.devices
  - swift.storage-services
{% endif %}
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:proxy',[]) %}
  - swift.proxy-cert
  - swift.repos
  - swift.rings
  - swift.proxy-services
{% endif %}
