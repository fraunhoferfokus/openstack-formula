{# only included on storage-nodes #}
{% for zone in pillar['swift-zones'] %}
  {% for dev in pillar['swift-devices'][zone] %}
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
{% endfor %}
