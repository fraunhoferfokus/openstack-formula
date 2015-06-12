include:
  - swift.packages
  - swift.config
  - swift.dirs
  - swift.rsyslog
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:storage',[]) %}
  - swift.devices
  - swift.requirements
  - swift.storage-services
{% endif %}
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:proxy',[]) %}
  - swift.proxy-cert
  - swift.repos
  - swift.rings
  - swift.proxy-services
{% endif %}
{%- if salt['pillar.get'](
    'swift:constraints:max_header_size', False) %}
  - swift.patch
{%- endif %}
