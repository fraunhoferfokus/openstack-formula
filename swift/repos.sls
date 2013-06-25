{% if grains['oscodename'] == 'precise' %}
ubuntu-cloud-key:
  cmd:
    - run
    - name: apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5EDB1B62EC4926EA && echo "changed=yes comment='Added key EC4926EA for repo ubuntu-cloud'"
    - stateful: True
    - unless: apt-key list | grep -q EC4926EA

ubuntu-cloud-repo:
  pkgrepo:
    - managed
    - name: deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/{{pillar['openstack-release']}} main
    - keyid: 5EDB1B62EC4926EA
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - python-swiftclient
{% endif %}
