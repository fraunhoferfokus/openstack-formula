{# Only included on proxy-nodes #}
swift-proxy:
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
