#!/usr/bin/env bash

# This wrapper script sets our Ubuntu versions and mirrors correctly before starting packer.

#############
# Configuration
# Explicit mirror selection (see commented example for format).
# Packages
ubuntu_mirror=""
#ubuntu_mirror="http://mirror.internode.on.net/pub/ubuntu/ubuntu/"
#############

set -e

# default boot wait of 4 seconds (all except bionic)
bootwait="4s"
#
case $1 in
"precise"*)
    ubuntu_version_full="12.04.5"
    ubuntu_version_short="12.04/"
    ubuntu_version_codename="precise"
  ;;
"trusty"*)
    ubuntu_version_full="14.04.5"
    ubuntu_version_short="14.04/"
    ubuntu_version_codename="trusty"
  ;;
"xenial"*)
    ubuntu_version_full="16.04.5"
    ubuntu_version_short="16.04/"
    ubuntu_version_codename="xenial"
  ;;
"bionic"*)
    ubuntu_version_full="18.04"
    # Not relevant for bionic due to way URLs are structured below
    ubuntu_version_short=""
    ubuntu_version_codename="bionic"
    bootwait="10s"
  ;;
  *)
    echo "usage: $0 [precise|trusty|xenial|bionic]"
    exit 1
  ;;
esac


echo "Started at $(date)"

if [ "$1" == "bionic" ]; then
  cdimages_mirror_file="cdimages_mirror.bionic.txt"
  if [ ! -f "$cdimages_mirror_file" ]; then
    echo "Error: '${cdimages_mirror_file}' file does not exist? Should be part of the repo...."
    exit 1
  fi
  echo "Using 'cdimages_mirror.bionic.txt' due to needing alternate installer on 18.04 / Bionic (standard mirrors only include live installer CDs)"
  echo "See https://wiki.ubuntu.com/BionicBeaver/ReleaseNotes#Server_installer for more details"
else
  cdimages_mirror_file="cdimages_mirror.txt"
  if [ ! -f "$cdimages_mirror_file" ]; then
	  echo "You must create a file called '${cdimages_mirror_file}' in this directory, with a mirror from:"
	  echo "https://launchpad.net/ubuntu/+cdmirrors"
	  echo "The file should contain a single line, of the URI of the 'http' link next to any mirror on the page above."
	  echo "Include the trailing slash, example:"
	  echo "http://mirror.internode.on.net/pub/ubuntu/releases/"
	  exit 1
  fi
fi

ubuntu_cd_mirror=$(cat "$cdimages_mirror_file")
cd_mirror_proto="$(echo $ubuntu_cd_mirror | grep :// | sed -e's,^\(.*://\).*,\1,g')"
if [[ "$cd_mirror_proto" != "http://" && "$cd_mirror_proto" != "https://" ]]; then
	echo "Error - Invalid format for '${cdimages_mirror_file}' file, it must contain a single line"
	echo "with a URL prefix, example:"
	echo "http://mirror.internode.on.net/pub/ubuntu/releases/"
	exit 1
fi

# Pick a mirror, if none has already ben specified for package retrievals during installation.
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
cp http/${ubuntu_version_codename}_preseed_template.cfg http/preseed.cfg
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
perl -pi -e "s|ISO_URL|${ubuntu_cd_mirror}${ubuntu_version_short}${ubuntu_iso_filename}|g" ubuntu_iso_to_ovf.json
bootcommand=$(cat scripts/${ubuntu_version_codename}.boot_command)
perl -pi -e "s|BOOTCOMMAND|${bootcommand}|g" ubuntu_iso_to_ovf.json
perl -pi -e "s|BOOTWAIT|${bootwait}|g" ubuntu_iso_to_ovf.json
perl -pi -e "s|UBUNTU_VERSION_FULL|${ubuntu_version_full}|g" ubuntu_iso_to_ovf.json

# ISO Checksum. Use an upstream trusted source rather than a mirror for this part.
shasums_filename="cdimages_SHA256SUMS"
if [ "$ubuntu_version_codename" == "bionic" ]; then
  # alternate installer comes from a specific mirror, SHA checksums for it not in releases.ubuntu.com list which sucks a little...
  shasums_url="${ubuntu_cd_mirror}SHA256SUMS"
else
  shasums_url="http://releases.ubuntu.com/${ubuntu_version_short}SHA256SUMS"
fi
wget -O "${shasums_filename}" "$shasums_url"
iso_checksum_value=$(grep "${ubuntu_iso_filename}" "${shasums_filename}" | cut -d" " -f1)
perl -pi -e "s|ISO_CHECKSUM|${iso_checksum_value}|g" ubuntu_iso_to_ovf.json

# Delete existing packer output directory, otherwise packer fails.
if [ -d "output-virtualbox-iso" ]; then
	rm -rf "output-virtualbox-iso"
fi

# Run packer.
packer build ubuntu_iso_to_ovf.json

set +x

echo "Completed at $(date)"
