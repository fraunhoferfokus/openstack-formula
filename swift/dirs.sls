{# On all Swift-nodes: #}
/etc/swift:
  file.directory:
    - user: {{ pillar.get('swift:user','swift') }}
    - group: {{ pillar.get('swift:group','swift') }}
    - mode: 750
    - recurse:
      - user
      - group
    - require:
      - pkg: swift-base-pkgs
{% if grains['id'] in pillar.get('swift:nodes:proxy',[]).items() %}
    - watch:
  {% for builder in pillar['swift:builder_ports'].keys() %}
      - cmd: /etc/swift/{{builder}}
  {% endfor %}
{% endif %}

{% if grains['id'] in pillar.get('swift:nodes:proxy',[]).items() %}
/home/swift/keystone-signing:
  file.directory:
    - user: {{ pillar.get('swift:user','swift') }}
    - group: {{ pillar.get('swift:group','swift') }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
{% endif %}

{% if grains['id'] in pillar.get('swift:nodes:storage',[]).items() %}
/srv/node:
  file.directory:
    - user: {{ pillar.get('swift:user','swift') }}
    - group: {{ pillar.get('swift:group','swift') }}
    - recurse:
      - user
      - group

/var/cache/swift:
  file.directory:
    - user: {{ pillar.get('swift:user','swift') }}
    - group: {{ pillar.get('swift:group','swift') }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
{% endif %}
