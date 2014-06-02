/etc/swift/swift.conf:
  file.managed:
    - source: salt://swift/swift.conf
    - template: jinja
    - user: root
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

  {% for builder, base_port in salt['pillar.get']('swift:builder_ports',{'account.builder':6002,'container.builder':6001,'object.builder':6000}).iteritems() %}
    {% set type = builder.split('.')[0] %}
/etc/swift/{{ type }}-server:
  file.directory:
    - user: root
    - group: swift
    - mode: 750

    {% for zone in salt['pillar.get']('swift:devices',{}).keys() %}
/etc/swift/{{ type }}-server/{{ zone[1] }}.conf:
  file.managed:
    - source: salt://swift/notproxy-server.jinja
    - template: jinja
    - user: root
    - group: swift
    - mode: 640
    - require:
       - file: /etc/swift/{{ type }}-server
    - context:
       bind_port: {{ base_port + zone[1]|int * 10 }}
       type: {{ type }}
       mount_point: {{ salt['pillar.get']('swift:devices:'+ zone[1] +':mnt') }}
       user: {{ salt['pillar.get']('swift:user','swift') }}
       log_facility: LOG_LOCAL{{zone[1]|int + 1}}
    {% endfor %}
  {% endfor %}
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
