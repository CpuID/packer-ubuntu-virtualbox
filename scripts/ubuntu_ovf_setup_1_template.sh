#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

set -x
set -e

cat > "/etc/apt/sources.list" << EOF
deb http://MIRROR_HOSTNAMEMIRROR_DIRECTORY MIRROR_SUITE main restricted universe multiverse
deb http://MIRROR_HOSTNAMEMIRROR_DIRECTORY MIRROR_SUITE-updates main restricted universe multiverse
deb http://MIRROR_HOSTNAMEMIRROR_DIRECTORY MIRROR_SUITE-backports main restricted universe multiverse
deb http://MIRROR_HOSTNAMEMIRROR_DIRECTORY MIRROR_SUITE-security main restricted universe multiverse
EOF

# Perform an update and full upgrade.
apt-get update
apt-get -y --force-yes dist-upgrade

# Install necessary libraries for guest additions and Vagrant NFS Share
apt-get install -y --force-yes linux-headers-$(uname -r) build-essential dkms nfs-common

# Setup sudo to allow no-password sudo for "admin"
groupadd -r admin
usermod -a -G admin vagrant
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

# Change vagrant and root user shells to real bash.
chsh -s $(which bash) vagrant
chsh -s $(which bash) root

# Once we have an OVF, the network comes online as eth1 not eth0.
# The default /etc/network/interfaces has eth0.
# Swap eth0 for eth1 so it boots a bit cleaner.
#sed -i -e 's/eth0/eth1/' /etc/network/interfaces
# Cleaner network setup? test it.
cat > "/etc/network/interfaces" << EOF
# Loopback
auto lo
iface lo inet loopback
# Optional interfaces (if they exist)
# eth0
allow-hotplug eth0
iface eth0 inet dhcp
# eth1
allow-hotplug eth1
iface eth1 inet dhcp
EOF

# Purge any old VirtualBox Guest Additions installed via apt.
apt-get -y -q purge virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11

# Reboot so we can start the next provisioner on our latest kernel.
reboot
sleep 60
service networking stop
