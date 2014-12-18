#!/usr/bin/env bash

# This wrapper script searches for and populates the latest Ubuntu OVF filename in our JSON, before calling packer.

echo "Started at $(date)"

set -e

iso_output_dir="output-virtualbox-iso"
latest_ubuntu_ovf_filename=$(find "${iso_output_dir}" -type f -name "*.ovf" -print0 | xargs -0 ls -1t | head -n 1)
if [ -z "${latest_ubuntu_ovf_filename}" ]; then
	echo "Error - We cannot find any OVF files in the directory '${iso_output_dir}'. Cannot proceed."
	exit 1
fi

echo "Using OVF Filename '${latest_ubuntu_ovf_filename}'."

# Substitute our OVF filename in packer JSON.
cp ubuntu_ovf_to_box_template.json ubuntu_ovf_to_box.json
perl -pi -e "s|UBUNTU_OVF_FILENAME|${latest_ubuntu_ovf_filename}|g" ubuntu_ovf_to_box.json

# Run packer.
packer build ubuntu_ovf_to_box.json

echo "Completed at $(date)"
