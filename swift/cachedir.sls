{# only included on storage-nodes #}
/var/swift/recon:
  file.directory:
    - user: {{ pillar['swift-user'] }}
    - group: {{ pillar['swift-group'] }}
    - mode: 750
    - recurse:
      - user
      - group
    - makedirs: True
