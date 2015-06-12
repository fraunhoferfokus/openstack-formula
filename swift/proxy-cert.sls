swift-proxy-cert:
  cmd.run:
    {# TODO: change -new to -newkey rsa:2048 or even better: #}
    {# -newkey {{pillar[...]['alg']}}:{{pillar[...]['bits']}} #}
    - name: openssl req -new -x509 -nodes -out /etc/swift/cert.crt -keyout /etc/swift/cert.key -subj "/C={{salt['pillar.get']('swift:proxy_cert:Country')}}/ST={{salt['pillar.get']('swift:proxy_cert:State')}}/L={{salt['pillar.get']('swift:proxy_cert:Locality')}}/O={{salt['pillar.get']('swift:proxy_cert:Org')}}/OU={{salt['pillar.get']('swift:proxy_cert:OrgUnit')}}/CN={{salt['pillar.get']('swift:proxy_cert:CommonName')}}/" && echo "changed=yes comment='Created new crt/key pair /etc/swift/cert.crt, /etc/swift/cert.key'"
    - stateful: True
    - unless: ls /etc/swift/cert.crt /etc/swift/cert.key
