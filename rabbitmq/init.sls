{%- from 'openstack/defaults.jinja' import openstack_defaults %}
rabbitmq-server:
  pkg:
    - installed
  service:
    - running

rabbitmq-user:
  rabbitmq_user.present:
    - name: {{ salt['pillar.get'](
                    'openstack:rabbitmq:userid',
                    openstack_defaults.rabbitmq.userid) }}
    - password: '{{ salt['pillar.get'](
                        'openstack:rabbitmq:password',
                        openstack_defaults.rabbitmq.password) }}'
    - perms:
          - '/':
              - '.*'
              - '.*'
              - '.*'

rabbitmq-vhost:
  rabbitmq_vhost.present:
    - name: '/'
    - owner: {{ salt['pillar.get']('openstack:rabbitmq:userid') }}

{% if salt['pillar.get']('openstack:rabbitmq:userid') != 'guest' %}
rabbimq-guestuser:
  rabbitmq_user.absent:
    - name: guest
{% endif %}
