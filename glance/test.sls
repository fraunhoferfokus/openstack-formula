grml96-small-2014.11:
    glance.image_present:
      - visibility: public
      - checksum: 0f5ce5d180becb2c3c0c1e7a2b8aade9
      - location: http://download.grml.org/grml96-small_2014.11.iso
      #- wait_for: saving

grml32-small_2014.11:
    glance.image_present:
      - checksum: 038b3d741d20cca989579cb71436cfce
      - location: http://download.grml.org/grml32-small_2014.11.iso

ubuntu-cloud-trusty:
    glance.image_present:
      - location: http://cloud-images.ubuntu.com/trusty/20150901.1/trusty-server-cloudimg-amd64-disk1.img

cirros-amd64-3.4:
    glance.image_present:
        - location: https://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
        #- wait_for:
