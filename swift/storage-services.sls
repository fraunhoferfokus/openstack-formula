{# Only included for storage-nodes #}
rsync:
  service.running:
    - enable: True
    - require:
      - file: /etc/rsyncd.conf
      - pkg: swift-storage-pkgs

{# TODO: Copy the ringfiles from proxy to all storage nodes #}
{% for ringfile in pillar['swift-ringfile-hashes'].keys() %}
  {% set ring = ringfile.split('/')[-1].split('.')[0] %}
storage-services-{{ring}}:
  service.running:
    - enable: True
    - require:
      - file: {{ringfile}}
      - file: /var/cache/swift
    - watch:
      - file: {{ringfile}}
    - names:
  {% if ring in ['container','object'] %}
    {% set service_postfixes = ['','-auditor','-replicator','-updater'] %}
  {% elif ring == 'account' %}
    {% set service_postfixes = ['','-auditor','-reaper','-replicator'] %}
  {% endif %}
  {% for postfix in service_postfixes %}
      - swift-{{ring}}{{postfix}}
  {% endfor %}
{% endfor %}
