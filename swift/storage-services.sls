{# Only included for storage-nodes #}
rsync:
  service.running:
    - enable: True
    - require:
      - file: /etc/rsyncd.conf
      - pkg: swift-storage-pkgs

{# TODO: Copy the ringfiles from proxy to all storage nodes #}

{% for type in ['account','container','object'] %}
  {% if type in ['container','object'] %}
    {% set service_postfixes = ['','-auditor','-replicator','-updater'] %}
  {% elif type == 'account' %}
    {% set service_postfixes = ['','-auditor','-reaper','-replicator'] %}
  {% endif %}
  {% if salt['pillar.get']('swift:all_in_one', False) %}
    {% for postfix in service_postfixes %}
{{ type }}{{postfix}}:
  service:
    - dead

  file.managed:
    - name: /etc/init/swift-{{ type }}{{postfix}}.override
    - contents: "manual\n"
    - user: root
    - group: root
    - mode: 0644

      {% for zone in salt['pillar.get']('swift:devices',{}).keys() %}
/etc/init/swift-{{ type }}{{ postfix }}-{{ zone[1] }}.conf:
  file.managed:
    - source: salt://swift/init_swift__conf.jinja
    - template: jinja
    - saltenv: OpenStack
    - user: root
    - group: root
    - mode: 755
    - context:
        type: {{ type }}{{ postfix }}
        num: {{ zone[1] }}

swift-{{ type }}{{ postfix }}-{{ zone[1] }}:
  service.running:
    - enable: True
    - require:
      - file: /etc/init/swift-{{ type }}{{ postfix }}-{{ zone[1] }}.conf
      - file: /etc/swift/{{ type }}-server/{{ zone[1]|int - 1 }}.conf
      - cmd: /etc/swift/{{ type }}.builder
      - file: /var/cache/swift
      {% endfor %}
    {% endfor %}

  {# If not all-in-one: #}
  {% else %}
storage-services-{{type}}:
  service.running:
    - enable: True
    - require:
      - cmd: /etc/swift/{{ type }}.builder
      - file: /var/cache/swift
      - file: /etc/swift/{{ type }}-server.conf
    {% for zone in salt['pillar.get']('swift:devices').keys() %}
      {% set dev = salt['pillar.get']('swift:devices:'+  zone +':dev') %}
      - file: /srv/node/{{ dev.split('/')[-1] }}
    {% endfor %}
    - watch:
      - cmd: /etc/swift/{{ type }}.builder
      - file: /etc/swift/{{ type }}-server.conf
    {% for zone in salt['pillar.get']('swift:devices').keys() %}
      {% set dev = salt['pillar.get']('swift:devices:'+  zone +':dev') %}
      - file: /srv/node/{{ dev.split('/')[-1] }}
    {% endfor %}
    - names:
    {% for postfix in service_postfixes %}
      - swift-{{type}}{{postfix}}
    {% endfor %}
  {% endif %}
{% endfor %}
