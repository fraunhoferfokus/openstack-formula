{% if grains['id'] in pillar['swift-nodes']['storage'] %}
/srv/node:
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - recurse:
      - user
      - group

  {% for dev in pillar['swift-devices'] %}
/srv/node/{{ dev.split('/')[-1] }}:
  mount.mounted:
    - device: {{dev}}
    - fstype: xfs
    - mkmnt: True
    - opts: 
      - noatime
      - nodiratime
      - nobarrier
      - logbufs=8
    - persist: True
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - require:
      - file: /srv/node
  {% endfor %}
{% endif %}
