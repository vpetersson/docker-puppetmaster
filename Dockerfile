# vpetersson/puppetmaster
#
# VERSION               0.0.1

FROM ubuntu:14.04
MAINTAINER Viktor Petersson <vpetersson@wireload.net>

# Refresh apt
RUN apt-get update

# Upgrade apt just to be safe
RUN apt-get -y upgrade

# Install pre-dependencies
RUN apt-get  -y install wget

# Install Puppet
RUN wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb -O /tmp/puppet-repo.deb
RUN dpkg -i /tmp/puppet-repo.deb
RUN rm /tmp/puppet-repo.deb
RUN apt-get update
RUN apt-get install -y puppetmaster-passenger

VOLUME [/var/lib/puppet,/etc/puppet/modules,/etc/puppet/manifests]

EXPOSE 8140

ADD start.sh /start.sh

CMD /start.sh
