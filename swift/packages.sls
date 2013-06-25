swift-base-pkgs:
  pkg:
    - installed
    - names:
{% for pkg in pillar['swift-pkgs']['base'] %}
      - {{ pkg }}
{% endfor %}

{% if pillar['swift-nodes']['storage'] %}
  {% if grains['id'] in pillar['swift-nodes']['storage'] %}
swift-storage-pkgs:
  pkg:
    - installed
    - names:
    {% for pkg in pillar['swift-pkgs']['storage'] %}
      - {{ pkg }}
    {% endfor %}
  {% endif %}
{% endif %}

{% if pillar['swift-nodes']['proxy'] %}
  {% if grains['id'] in pillar['swift-nodes']['proxy'] %}
swift-proxy-pkgs:
  pkg:
    - installed
    - names:
    {% for pkg in pillar['swift-pkgs']['proxy'] %}
      - {{ pkg }}
    {% endfor %}
    {% if grains['oscodename'] == 'precise' %}
    - require:
      - pkgrepo: ubuntu-cloud-repo
    {% endif %}
  {% endif %}
{% endif %}
