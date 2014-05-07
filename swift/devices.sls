{# only included on storage-nodes #}
{% for zone in pillar['swift:zones'] %}
  {% for dev in pillar.get('swift:devices:'+zone,[]) %}
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
    - user: {{ pillar.get('swift:user','swift') }}
    - group: {{ pillar.get('swift:group','swift') }}
    - require:
      - file: /srv/node
  {% endfor %}
{% endfor %}
