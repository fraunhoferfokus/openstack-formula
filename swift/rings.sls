{# PROXY STUFF #}
{% if grains.get('id') in pillar.get('swift:nodes:storage',[]) %}
  {% for builder in pillar['swift-builder-ports'].keys() %}
/etc/swift/{{builder}}:
  cmd.run:
    - cwd: /etc/swift
    - name: swift-ring-builder {{builder}} create {{pillar['swift-rings']['part-pwr']}} {{pillar['swift-rings']['replicas']}} {{pillar['swift-rings']['restrict']}} && echo "changed=yes comment='Created new builder /etc/swift/{{builder}}'" || (echo "changed=no comment='Failed to create new builder /etc/swift/{{builder}}'"; false)
    - stateful: True
    - unless: ls /etc/swift/{{builder}}
    - require:
      - pkg: swift-proxy-pkgs

    {% for zone in pillar['swift-zones'] %}
      {% for dev in pillar['swift-devices'][zone] %}

add_{{dev.split('/')[-1]}}_to_z{{zone}}_in_{{builder.split('.')[0]}}:
  cmd.run:
    - cwd: /etc/swift
    - name: swift-ring-builder {{builder}} add r{{pillar['swift-region']}}z{{zone}}-{{pillar['swift-ips']['storage-local']}}:{{pillar['swift-builder-ports'][builder]}}/{{dev.split('/')[-1]}} 100 && echo "changed=yes comment='Added {{dev}} to zone {{zone}} in region {{pillar['swift-region']}} for builder {{builder}}'" || (echo "changed=no comment='Failed to add {{dev}} to zone {{zone}} in region {{pillar['swift-region']}} for builder {{builder}}'"; false)
    - stateful: True
    - require:
      - cmd: /etc/swift/{{builder}}
    - unless: swift-ring-builder {{builder}} list_parts z{{zone}}-{{pillar['swift-ips']['storage-local']}}:{{pillar['swift-builder-ports'][builder]}}/{{dev.split('/')[-1]}}

      {% endfor %}
    {% endfor %}

swift-ring-builder {{builder}} rebalance:
  cmd.wait:
    - cwd: /etc/swift
    - require:
      - cmd: /etc/swift/{{builder}}
    - watch:
      - cmd: /etc/swift/{{builder}}
    {% for zone in pillar['swift-zones'] %}
      {% for dev in pillar['swift-devices'][zone] %}
      - cmd: add_{{dev.split('/')[-1]}}_to_z{{zone}}_in_{{builder.split('.')[0]}}
      {% endfor %}
    {% endfor %}
  {% endfor %}
{% endif %}

{# STORAGE STUFF #}
{% if grains.get('id') in pillar.get('swift:nodes:storage',[]) %}
  {% for ringfile, hash in pillar['swift-ringfile-hashes'] %}
{{ ringfile }}:
  file.managed:
    - source: salt://swift/{{ ringfile.split('/')[-1] }}
    - source_hash: {{ hash }}
  {% endfor %}
{% endif %}
