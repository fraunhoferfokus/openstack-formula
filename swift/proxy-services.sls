{# Only included on proxy-nodes #}
swift-proxy:
  service.running:
    - enable: True
    - requires:
      - pkg: swift-proxy-pkgs
      - service: memcached
  {% for builder in salt['pillar.get']('swift:builder_ports', {'account.builder':0, 'container.builder':0,'object.builder':0}).keys() %}
      - cmd: /etc/swift/{{builder}}
  {% endfor %}
      - file: /etc/swift/proxy-server.conf
    - watch:
      - file: /etc/swift/proxy-server.conf

memcached:
  service.running:
    - enable: True
    - require:
      - file: /etc/memcached.conf
      - pkg: swift-base-pkgs
    - watch:
      - file: /etc/memcached.conf
