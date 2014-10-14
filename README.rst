=================
openstack-formula
=================

A saltstack formula to deploy OpenStack.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

.. note::
    
    This formula uses the openvswitch-formula and the mysql-formula and 
    assumes both are present in the same Salt-Environment.

Pillar-Data common between States
=================================
Some settings are used by several or even all states - like the address of 
the controller. We grouped those under the pillar-key ``openstack`` and
in many places those common settings are used if no value specific for
the given service is found in your Pillar.

Minimal common Pillar::

    openstack:
        controller_address: controller.example.com
        rabbitmq:
            password: 'blVobc_common_pX8_rabbitmq_Trhtj_password_UW1guAQ'
        neutron:
            shared_secret: 'I took my Shared Secret from the documentation'

Available states
================

.. contents::
    :local:

``pkgrepo``
-----------
Add repositories like Ubuntu's `Cloud Archive`_ if necessary.

.. _Cloud Archive: https://wiki.ubuntu.com/ServerTeam/CloudArchive

``rabbitmq``
------------
Install and configure rabbitmq for use with OpenStack.

``keystone``
------------
Install and configure OpenStack's Keystone and it's database.

Minimal data for Pillar::

    keystone:
      database: 
        password: 'sUlPalrGnWTnsg_keystone_db_pass_lTNA2Zse7XkGlA'

``neutron.server``
------------------
Install and configure the server-part of OpenStack's Neutron.

Minimal state-specific Pillar::

    neutron:
      common:
        DEFAULT:
          admin_password: service_bFdYs/+LF0kaD_pass
        database:
          password: neutron_qg2bD0_database_gCwXD_pass


``glance``
----------
Install and configure OpenStack's Glance.

Minimal state-specific Pillar::

    glance:
      database:
        password: glance_db_pass
      keystone:
        admin_password: glance_IotdLq_service_Df2HN2_pass

``nova.controller``
-------------------
Install and configure Nova services on the controller.

Minimal data to set in Pillar::

    nova:
      database:
        password: 'Pkbcj5QBD+69pQ_nova_db_pass_UqjG5OzxyPzn3A'
