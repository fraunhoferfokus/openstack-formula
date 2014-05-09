{# On all Swift-nodes: #}
/etc/swift:
  file.directory:
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - mode: 750
    - recurse:
      - user
      - group
    - require:
      - pkg: swift-base-pkgs
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:proxy',[]) %}
    - watch:
  {% for builder in ['account.builder','container.builder','object.builder'] %}
      - cmd: /etc/swift/{{builder}}
  {% endfor %}
{% endif %}

{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:proxy',[]) %}
/home/swift/keystone-signing:
  file.directory:
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
{% endif %}

{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:storage',[]) %}
/srv/node:
  file.directory:
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - recurse:
      - user
      - group

/var/cache/swift:
  file.directory:
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
{% endif %}
