#!/bin/bash

function initiate_instance {
  echo "Starting node initiation..."

  # Make Apache config hostname dynamic
  sed -i -e 's/SSLCertificateFile.*$/SSLCertificateFile      \/var\/lib\/puppet\/ssl\/certs\/${HOSTNAME}.pem/g' /etc/apache2/sites-enabled/puppetmaster.conf
  sed -i -e 's/SSLCertificateKeyFile.*$/SSLCertificateKeyFile   \/var\/lib\/puppet\/ssl\/private_keys\/${HOSTNAME}.pem/g' /etc/apache2/sites-enabled/puppetmaster.conf

  # Fire up regular Puppet master to generate
  # certificates and folder structure.
  # This shouldn't take more than five seconds.
  echo "Starting Puppet to generate certificates..."
  timeout 5 puppet master --no-daemonize

  echo "Node initation completed..."
}

function grant_acl_permission {
  # Only append if missing
  FINDINFILE=$(grep "#Dockerized ACL" /etc/puppet/auth.conf)
  if [ -z "$FINDINFILE" ]; then
    ACLSTANZA="#Dockerized ACL\npath /\nauth any\nallow_ip $ACLGRANT\n"
    sed -i "/^# deny everything/ i $ACLSTANZA" /etc/puppet/auth.conf
  fi
}

# Assume that this is a new instance if
# no SSL file for the hostname exist.
if [ ! -f /var/lib/puppet/ssl/certs/$(hostname).pem ]; then
  initiate_instance
fi

# If any ACL was given, append this to the config.
if [ -n "$ACLGRANT" ]; then
  echo "Adding ACL stanza..."
  grant_acl_permission
fi

# Start Apache
echo "Starting Apache..."
apache2ctl -D FOREGROUND
