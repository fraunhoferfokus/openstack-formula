rabbitmq-server:
  pkg:
    - installed
  service:
    - running

rabbitmq-user:
  rabbitmq_user.present:
    - name: {{ salt['pillar.get']('rabbitmq:user','openstack') }}
    - password: '{{ salt['pillar.get']('rabbitmq:password') }}'
  {% if salt['pillar.get']('openstack:rabbitmq:user') != guest %}
  rabbitmq_user.absent:
    - name: guest
  {% endif %}