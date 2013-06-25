swift-base-pkgs:
  pkg:
    - installed
    - names:
      - swift
      - openssh-server
      - rsync
      - memcached
      - python-netifaces
      - python-xattr
      - python-memcache

{% if grains['id'] in pillar['swift-nodes']['storage'] %}
swift-storage-pkgs:
  pkg:
    - installed
    - names:
      - swift-account
      - swift-container
      - swift-object
      - xfsprogs
{% endif %}

{% if grains['id'] in pillar['swift-nodes']['proxy'] %}
swift-proxy-pkgs:
  pkg:
    - installed
    - names:
      - swift-proxy
      - memcached
      - python-keystoneclient
      - python-swiftclient
      - python-webob
    {% if grains['oscodename'] == 'precise' %}
    - require:
      - pkgrepo: ubuntu-cloud-repo
    {% endif %}
{% endif %}
