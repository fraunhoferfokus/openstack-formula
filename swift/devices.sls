{# only included on storage-nodes #}
{% for zone, devices in salt['pillar.get']('swift:devices').iteritems() %}
  {% for dev in devices %}
    {% if dev.split('/')[1] != 'dev' %}
{{dev}}:
  cmd.run:
    - name: truncate -s {{ salt['pillar.get']('swift:dev_size', '1GB') }} {{dev}} && ( mkfs.xfs {{dev}} && echo 'changed=yes comment="Truncated and formated with XFS."' || ( echo 'changed=no comment="Failed to create XFS on {{dev}}"'; false) ) || ( echo 'changed=no comment="Failed to truncate {{dev}} to {{ salt['pillar.get']('swift:dev_size', '1GB') }}"'; false)
    - stateful: True
    - unless: ls {{dev}}
    {% endif %}
/srv/node/{{ dev.split('/')[-1] }}:
  mount.mounted:
    - device: {{dev}}
    - fstype: xfs
    - mkmnt: True
    - opts: 
    {% if dev.split('/')[1] != 'dev' %}
      - loop
    {% endif %}
      - noatime
      - nodiratime
      - nobarrier
      - logbufs=8
    - persist: True
    - require:
      - pkg: swift-storage-pkgs
  file.directory:
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - require:
      - file: /srv/node
    {% if dev.split('/')[1] != 'dev' %}
      - cmd: {{ dev }}
    {% endif %}
  {% endfor %}
{% endfor %}
