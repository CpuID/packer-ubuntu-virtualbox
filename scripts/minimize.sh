#!/bin/bash -eux

# This is to fill all unused space with 0s, in order to
# optimize compression after the image is created

# dd will fail when the disk fills up, we will ignore that error
set +e
sudo dd if=/dev/zero of=/EMPTY bs=1M
set -e

sudo rm -f /EMPTY