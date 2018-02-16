#!/usr/bin/env bash

sudo apt-get -y autoremove
sudo apt-get -y clean
sudo rm -rf VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?
sudo rm -rf /vagrant
sudo mkdir /vagrant