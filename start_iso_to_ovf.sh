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
# Packages
ubuntu_mirror=""
#ubuntu_mirror="http://mirror.internode.on.net/pub/ubuntu/ubuntu/"

#############

echo "Started at $(date)"

if [ ! -f "cdimages_mirror.txt" ]; then
	echo "You must create a file called 'cdimages_mirror.txt' in this directory, with a mirror from:"
	echo "https://launchpad.net/ubuntu/+cdmirrors"
	echo "The file should contain a single line, of the URI of the 'http' link next to any mirror on the page above."
	echo "Include the trailing slash, example:"
	echo "http://mirror.internode.on.net/pub/ubuntu/releases/"
	exit 1
fi
ubuntu_cd_mirror=$(cat "cdimages_mirror.txt")
cd_mirror_proto="$(echo $ubuntu_cd_mirror | grep :// | sed -e's,^\(.*://\).*,\1,g')"
if [[ "$cd_mirror_proto" != "http://" && "$cd_mirror_proto" != "https://" ]]; then
	echo "Error - Invalid format for 'cdimages_mirror.txt' file, it must contain a single line"
	echo "with a URL prefix, example:"
	echo "http://mirror.internode.on.net/pub/ubuntu/releases/"
	exit 1
fi

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

# ISO URL.
cp ubuntu_iso_to_ovf_template.json ubuntu_iso_to_ovf.json
ubuntu_iso_filename="ubuntu-${ubuntu_version_full}-server-amd64.iso"
perl -pi -e "s|ISO_URL|${ubuntu_cd_mirror}${ubuntu_version_short}/${ubuntu_iso_filename}|g" ubuntu_iso_to_ovf.json

# ISO Checksum. Use an upstream trusted source rather than a mirror for this part.
sha1sums_filename="cdimages_SHA1SUMS"
wget -q -O "${sha1sums_filename}" "http://releases.ubuntu.com/${ubuntu_version_short}/${sha1sums_filename}"
iso_checksum_value=$(grep "${ubuntu_iso_filename}" "${sha1sums_filename}" | cut -d" " -f1)
perl -pi -e "s|ISO_CHECKSUM|${iso_checksum_value}|g" ubuntu_iso_to_ovf.json

# Run packer.
packer build ubuntu_iso_to_ovf.json

echo "Completed at $(date)"
