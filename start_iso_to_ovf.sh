#!/usr/bin/env bash

set -e
set -x

# This wrapper script sets our Ubuntu mirrors correctly before starting packer.

# TODO - get the below values from somewhere dynamic.
# We will want to define the OS version, 12.04.4 and 12.04 somewhere, as well as precise, and the mirror hostname and path.

cp http/preseed_template.cfg http/preseed.cfg
perl -pi -e 's|MIRROR_HOSTNAME|mirror.internode.on.net|g' http/preseed.cfg
perl -pi -e 's|MIRROR_DIRECTORY|/pub/ubuntu/ubuntu/|g' http/preseed.cfg
perl -pi -e 's|MIRROR_SUITE|precise|g' http/preseed.cfg

cp scripts/ubuntu_ovf_setup_1_template.sh scripts/ubuntu_ovf_setup_1.sh
perl -pi -e 's|MIRROR_HOSTNAME|mirror.internode.on.net|g' scripts/ubuntu_ovf_setup_1.sh
perl -pi -e 's|MIRROR_DIRECTORY|/pub/ubuntu/ubuntu/|g' scripts/ubuntu_ovf_setup_1.sh
perl -pi -e 's|MIRROR_SUITE|precise|g' scripts/ubuntu_ovf_setup_1.sh

cp ubuntu_iso_to_ovf_template.json ubuntu_iso_to_ovf.json
perl -pi -e 's|MIRROR_URL|http://mirror.internode.on.net/pub/ubuntu/releases/12.04/ubuntu-12.04.4-server-amd64.iso|g' ubuntu_iso_to_ovf.json

packer build ubuntu_iso_to_ovf.json
