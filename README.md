# Dockerzied Puppet master

This is a fully working Dockerized Puppet master running on Ubuntu 14.04 with Apache and Passanger using the [official](https://docs.puppetlabs.com/guides/install_puppet/install_debian_ubuntu.html) instructions.

Given that Puppet runs within a Docker container, we cannot use the CLI for managing nodes. Instead, the container is configured to use the built-in API for these tasks. As an added benefit, we can then easily automate these tasks with scripts and other integrations. Some common examples have been provided below.

# Running the container

Before you start the container, it is important to understand how this container is intended to be run.

## Hostname

**tl;dr:** This must match the hostname your clients connect to.

It is important that you pass on the `-h puppet.local` where 'puppet.local' is the desired hostname of your puppet server. This variable will be used for the Puppet Master. If this hostname doesn't match the hostname your clients are connecting to, the puppet run will fail.


## Port

**tl;dr:** Just use the standard port (8140).

The flag `-p 8140:8140` simply means that port on the host should bind to 8140 inside the container. Don't get fancy here. If you do, chances are that it will break.

## ACLGRANT (Optional)

**tl;dr:** This needs to match IP block you want to make API calls from. Be as restrictive as possible, as a lot of damage can be made.

By default, Puppet's API is configured to be very restrictive (as it should). However, in order to be able to remotely control Puppet via the API, we need to open this up. This is where this ACLGRANT flag comes into play. For instance, you can pass in '192.168.10.0/24' if you want to grant access to all these nodes.

The stanza that this will add to `auth.conf` is a follows:

    path /
    auth any
    allow_ip 192.168.10.0/24

**Any node within this block can administrate Puppet, so be careful.**

More information about this can be found [here](https://docs.puppetlabs.com/guides/rest_auth_conf.html#allowip)

## Volumes

**tl;dr:** This is where you store your permanant data outside of the container.

Since Docker containers are ephimeral by nature, we need to store all sensitive data outside of the container using volumes.

There are three different volumes that we will be using:

 * /var/lib/puppet
 * /etc/puppet/modules
 * /etc/puppet/manifests

Assuming this is a production environment, you need to be careful how you store these. `/var/lib/puppet` is where all the SSL certificates and reports are stored, while `/etc/puppet/modules` and `/etc/puppet/manifests` should be self explanatory for any Puppet user


## Example command

Here's an example of how the run could look like.

It is also important to note that if this is the first run, an SSL certificate for the hostname will be generated.

    docker run \
      --name puppetmaster \
      --restart always \
      -h puppet.local \
      -p 8140:8140 \
      -e 'ACLGRANT=a.b.c.d/24' \
      -v /path/to/datastore:/var/lib/puppet \
      -v /path/to/modules:/etc/puppet/modules \
      -v /path/to/manifests:/etc/puppet/manifests \
      -i -t wireload/puppetmaster

# Interaction

This container is designed to use the Puppet API for management. The full documentation is available [here](https://docs.puppetlabs.com/guides/rest_api.html).

Here are som common operations that you may want to use.

## Get status of nodes

If we want to get a list of all the certificates and their status, we can issue the following command:

    $ curl -k -H "Accept: pson" https://puppetmaster:8140/production/certificate_statuses/all

## Sign a node

Let's say that we want to sign the node 'mynode.local' that has a pending certificate request. We would then issue the following command:

    $ curl -k -X PUT -H "Content-Type: text/pson" --data '{"desired_state":"signed"}' https://puppetmaster:8140/production/certificate_status/mynode.local

## Revoke/delete a node

If we later decide to revoke the node, the recommended approach is to use the DELETE call (rather than revoking it). To do this, simply run the following command:

    $ curl -k -X DELETE -H "Accept: pson" https://puppetmaster:8140/production/certificate_status/mynode.local
