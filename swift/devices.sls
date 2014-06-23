{# only included on storage-nodes #}
{% for zone in salt['pillar.get']('swift:devices').keys() %}
  {% set dev = salt['pillar.get']('swift:devices:'+  zone +':dev') %}
  {% if dev.split('/')[1] != 'dev' %}
{{dev}}:
  cmd.run:
    - name: truncate -s {{ salt['pillar.get']('swift:dev_size', '1GB') }} {{dev}} && ( mkfs.xfs {{dev}} && echo 'changed=yes comment="Truncated and formated with XFS."' || ( echo 'changed=no comment="Failed to create XFS on {{dev}}"'; false) ) || ( echo 'changed=no comment="Failed to truncate {{dev}} to {{ salt['pillar.get']('swift:dev_size', '1GB') }}"'; false)
    - stateful: True
    - unless: ls {{dev}}
    - require:
    {% for key, value in salt['pillar.get']('swift:dev_requirements', {}).items() %}
      {% if value is string %}
      - {{ value.split('.')[0] }}: {{ key }}
      {% elif value is mapping %}
      - {{ value.keys()[0].split('.')[0] }}: {{ key }}
      {% endif %}
    {% endfor %}
  {% endif %}
/srv/node/{{ dev.split('/')[-1] }}:
  mount.mounted:
    - device: {{dev}}
    - fstype: xfs
    - mkmnt: True
    - opts: 
  {% if dev.split('/')[1] != 'dev' %}
      - loop
      - noauto {# because Ubuntu cannot reliably mount those from NFS #}
  {% endif %}
      - noatime
      - nodiratime
      - nobarrier
      - logbufs=8
    - persist: True
    - require:
      - pkg: swift-storage-pkgs
  {% if dev.split('/')[1] != 'dev' %}
      - cmd: {{ dev }} {% endif %}
  {% for key, value in salt['pillar.get']('swift:dev_requirements', {}).items() %}
    {% if value is string %}
      - {{ value.split('.')[0] }}: {{ key }}
    {% elif value is mapping %}
      - {{ value.keys()[0].split('.')[0] }}: {{ key }}
    {% endif %}
  {% endfor %}
  file.directory:
    - user: {{ salt['pillar.get']('swift:user','swift') }}
    - group: {{ salt['pillar.get']('swift:group','swift') }}
    - require:
      - file: /srv/node
  {% if dev.split('/')[1] != 'dev' %}
      - cmd: {{ dev }}
  {% endif %}
{% endfor %}
