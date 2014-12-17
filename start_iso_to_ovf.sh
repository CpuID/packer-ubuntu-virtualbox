#!/usr/bin/env bash

set -e

# This wrapper script sets our Ubuntu versions and mirrors correctly before starting packer.

# Precise
ubuntu_version_full="12.04.4"
ubuntu_version_short="12.04"
ubuntu_version_codename="precise"
# Trusty
#ubuntu_version_full="14.04.1"
#ubuntu_version_short="14.04"
#ubuntu_version_codename="trusty"

# Explicit mirror selection (see commented example for format).
ubuntu_mirror=""
#ubuntu_mirror="http://mirror.internode.on.net/pub/ubuntu/ubuntu/"

#############

# Pick a mirror, if none has already ben specified.
if [ -z "$ubuntu_mirror" ]; then
	echo "Fetching mirror from Ubuntu site."
	wget -q -O mirrors.txt "http://mirrors.ubuntu.com/mirrors.txt"
	ubuntu_mirror=$(head -n 1 mirrors.txt)
else
	echo "Explicit mirror specified."
fi

# Parse the Ubuntu mirror above into required variables.
mirror_proto="$(echo $ubuntu_mirror | grep :// | sed -e's,^\(.*://\).*,\1,g')"
mirror_url="$(echo ${ubuntu_mirror/$mirror_proto/})"
mirror_user="$(echo $mirror_url | grep @ | cut -d@ -f1)"
mirror_host="$(echo ${mirror_url/$mirror_user@/} | cut -d/ -f1)"
mirror_path="/$(echo $mirror_url | grep / | cut -d/ -f2-)"

echo ""
echo "Using '${ubuntu_mirror}' as our Ubuntu Mirror."
echo "Protocol: ${mirror_proto}"
echo "User (if any): ${mirror_user}"
echo "URL: ${mirror_url}"
echo "Host: ${mirror_host}"
echo "Path: ${mirror_path}"
echo ""

exit 0

set -x

# Substitute values as required.
cp http/preseed_template.cfg http/preseed.cfg
perl -pi -e "s|MIRROR_HOSTNAME|${mirror_host}|g" http/preseed.cfg
perl -pi -e "s|MIRROR_DIRECTORY|${mirror_path}|g" http/preseed.cfg
perl -pi -e "s|MIRROR_SUITE|${ubuntu_version_codename}|g" http/preseed.cfg

cp scripts/ubuntu_ovf_setup_1_template.sh scripts/ubuntu_ovf_setup_1.sh
perl -pi -e "s|MIRROR_HOSTNAME|${mirror_host}|g" scripts/ubuntu_ovf_setup_1.sh
perl -pi -e "s|MIRROR_DIRECTORY|${mirror_path}|g" scripts/ubuntu_ovf_setup_1.sh
perl -pi -e "s|MIRROR_SUITE|${ubuntu_version_codename}|g" scripts/ubuntu_ovf_setup_1.sh

cp ubuntu_iso_to_ovf_template.json ubuntu_iso_to_ovf.json
# TODO - substitute url below
perl -pi -e "s|MIRROR_URL|http://mirror.internode.on.net/pub/ubuntu/releases/12.04/ubuntu-12.04.4-server-amd64.iso|g" ubuntu_iso_to_ovf.json

# TODO - get SHA1 hash and substitute in JSON file for relevant iso.

# Run packer.
packer build ubuntu_iso_to_ovf.json
