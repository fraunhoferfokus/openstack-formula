/etc/swift/swift.conf:
  file.managed:
    - source: salt://swift/swift.conf
    - template: jinja
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - mode: 640
    - require:
      - file: /etc/swift
    
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:storage',[]) %}
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
{% endif %}

{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:proxy',[]) %}
/etc/memcached.conf:
  file.managed:
    - source: salt://swift/proxy_memcached.conf
    - template: jinja
    - require:
      - pkg: swift-base-pkgs

/etc/swift/proxy-server.conf:
  file.managed:
    - source: salt://swift/proxy-server.conf
    - template: jinja
    - require:
      - pkg: swift-proxy-pkgs
{% endif %}
