{# PROXY STUFF #}
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:storage',[]) %}
  {% for builder, base_port in salt['pillar.get']('swift:builder_ports',{'account.builder':6002,'container.builder':6001,'object.builder':6000}).iteritems() %}
/etc/swift/{{builder}}:
  cmd.run:
    - cwd: /etc/swift
    - name: swift-ring-builder {{builder}} create {{salt['pillar.get']('swift:rings:part_pwr', 18)}} {{salt['pillar.get']('swift:rings:replicas',3)}} {{salt['pillar.get']('swift:rings:restrict', 1)}} && echo "changed=yes comment='Created new builder /etc/swift/{{builder}}'" || (echo "changed=no comment='Failed to create new builder /etc/swift/{{builder}}'"; false)
    - stateful: True
    - unless: swift-ring-builder {{builder}}
    - require:
      - pkg: swift-proxy-pkgs

    {% for zone in salt['pillar.get']('swift:devices').keys() %}
      {% set dev = salt['pillar.get']('swift:devices:'+zone+':dev') %}
      {% set port = base_port + zone[1]|int * 10 %}

add_{{dev.split('/')[-1]}}_to_z{{zone[1]}}_in_{{builder.split('.')[0]}}:
  cmd.run:
    - cwd: /etc/swift
    - name: swift-ring-builder {{builder}} add r{{salt['pillar.get']('swift:region')}}z{{zone[1]}}-{{salt['pillar.get']('swift:IPs:storage_local')}}:{{ port }}/{{dev.split('/')[-1]}} 100 && echo "changed=yes comment='Added {{dev}} to zone {{zone[1]}} in region {{salt['pillar.get']('swift:region')}} for builder {{builder}}'" || (echo "changed=no comment='Failed to add {{dev}} to zone {{zone[1]}} in region {{salt['pillar.get']('swift:region')}} for builder {{builder}}'"; false)
    - stateful: True
    - require:
      - cmd: /etc/swift/{{builder}}
    - unless: swift-ring-builder {{builder}} list_parts z{{zone[1]}}-{{salt['pillar.get']('swift:IPs:storage_local')}}:{{ port }}/{{dev.split('/')[-1]}}

    {% endfor %}

swift-ring-builder {{builder}} rebalance:
  cmd.wait:
    - cwd: /etc/swift
    - require:
      - cmd: /etc/swift/{{builder}}
    - watch:
      - cmd: /etc/swift/{{builder}}
    {% for zone in salt['pillar.get']('swift:devices').keys() %}
      {% set dev = salt['pillar.get']('swift:devices:'+zone+':dev') %}
      - cmd: add_{{dev.split('/')[-1]}}_to_z{{zone[1]}}_in_{{builder.split('.')[0]}}
    {% endfor %}
  {% endfor %}
{% endif %}

{# STORAGE STUFF #}
{% if salt['grains.get']('id') in salt['pillar.get']('swift:nodes:storage',[]) %}
  {% for ringfile, hash in salt['pillar.get']('swift:ringfiles').iteritems() %}
{{ ringfile }}:
  file.managed:
    - source: salt://swift/{{ ringfile.split('/')[-1] }}
    - source_hash: {{ hash }}
  {% endfor %}
{% endif %}
