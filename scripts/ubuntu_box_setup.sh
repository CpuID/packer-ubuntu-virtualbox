#!/usr/bin/env bash

set -e
set -x

# Install wget to get public key from upstream.
# May already be installed, but we make sure.
sudo apt-get install -y --force-yes wget

# Installing vagrant keys
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R vagrant ~/.ssh

# Touch a test file for starters.
echo "this is a test file" > ~/test_file

#######################

# NOTE - Add any extra provisioner tasks you like here.
# Alternatively you can define extra provisioners in the Packer JSON file.
