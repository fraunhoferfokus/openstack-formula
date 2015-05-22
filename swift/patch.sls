{% if salt['pillar.get']('openstack:release', False) == 'grizzly' %}
/usr/share/pyshared/swift/common/wsgi.py:
    file.managed:
        - source: salt://swift/files/wsgi.py
        - user: root
        - group: root
        - mode: 644

/usr/lib/python2.7/dist-packages/swift/common/wsgi.py:
    file.symlink:
        - target: /usr/share/pyshared/swift/common/wsgi.py
{% endif %}
