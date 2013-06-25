/etc/swift:
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - mode: 750
    - require:
      - pkg: swift-base-pkgs

/etc/swift/swift.conf:
  file.managed:
    - source: salt://swift/swift.conf
    - template: jinja
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - mode: 640
    - require:
      - file: /etc/swift
    
{% if grains['id'] in pillar['swift-nodes']['storage'] %}
/etc/rsyncd.conf:
  file.managed:
    - source: salt://swift/rsyncd.conf
    - template: jinja
    - require:
      - pkg: swift-storage-pkgs
/etc/default/rsync:
  file.managed:
    - source: salt://swift/default_rsync
    - require:
      - pkg: swift-base-pkgs
rsync:
  service.running:
    - enable: True
    - require:
      - file: /etc/rsyncd.conf
      - pkg: swift-storage-pkgs
{% endif %}
