/etc/swift:
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - mode: 750
    - recurse:
      - user
      - group
    - require:
      - pkg: swift-base-pkgs
    - watch:
{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
  {% for builder in pillar['swift-builder-ports'].keys() %}
      - cmd: /etc/swift/{{builder}}
  {% endfor %}
{% endif %}

{% if grains['id'] in pillar['swift-nodes']['storage'] %}
/var/swift/recon:
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
{% endif %}

{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
/home/swift/keystone-signing:
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
{% endif %}
