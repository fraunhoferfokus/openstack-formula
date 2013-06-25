swift-proxy-cert:
  cmd.run:
    - name: openssl req -new -x509 -nodes -out /etc/swift/cert.crt -keyout /etc/swift/cert.key -subj "/C={{pillar['swift-proxy-cert']['Country']}}/ST={{pillar['swift-proxy-cert']['State']}}/L={{pillar['swift-proxy-cert']['Locality']}}/O={{pillar['swift-proxy-cert']['Org']}}/OU={{pillar['swift-proxy-cert']['OrgUnit']}}/CN={{pillar['swift-proxy-cert']['CommonName']}}/" && echo "changed=yes comment='Created new crt/key pair /etc/swift/cert.crt, /etc/swift/cert.key'"
    - stateful: True
    - unless: ls /etc/swift/cert.crt /etc/swift/cert.key
