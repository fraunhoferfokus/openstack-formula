rsyslog4swift:
  pkg.installed:
    - name: rsyslog
  service.enabled:
    - name: rsyslog
    - require:
      - file: /etc/rsyslog.d/10-swift.conf
      - file: /var/log/swift
{% if salt['pillar.get']('swift:logging:hourly_logs', False) %}
      - file: /var/log/swift/hourly
{% endif %}
    - watch:
      - file: /etc/rsyslog.d/10-swift.conf

/etc/rsyslog.d/10-swift.conf:
  file.managed:
    - source: salt://swift/rsyslog_swift.conf.jinja
    - saltenv: OpenStack
    - template: jinja

/var/log/swift:
  file.directory:
    - user: {{ salt['pillar.get']('swift:user', 'swift') }}
    - group: adm
    - mode: 775

{% if salt['pillar.get']('swift:logging:hourly_logs', False) %}
/var/log/swift/hourly:
  file.directory:
    - user: {{ salt['pillar.get']('swift:user', 'swift') }}
    - group: adm
    - mode: 775
    - require:
      - file: /var/log/swift
{% endif %}
