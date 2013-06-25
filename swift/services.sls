{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
proxy-server:
  service.running:
    - enabled: True
    - requires:
      - pkg: swift-proxy-pkgs
      - service: memcached
  {% for builder in pillar['swift-builder-ports'].keys() %}
      - cmd: /etc/swift/{{builder}}
  {% endfor %}

memcached:
  service.running:
    - enable: True
    - require:
      - file: /etc/memcached.conf
      - pkg: swift-base-pkgs
    - watch:
      - file: /etc/memcached.conf
{% endif %}

{% if grains['id'] in pillar['swift-nodes']['storage'] %}
rsync:
  service.running:
    - enable: True
    - require:
      - file: /etc/rsyncd.conf
      - pkg: swift-storage-pkgs
{% endif %}
