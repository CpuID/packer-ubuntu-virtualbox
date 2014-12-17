packer-ubuntu-virtualbox
========================

Packer templates for Ubuntu on Virtualbox for Vagrant (2 Stage - ISO to OVF, then OVF to Vagrant Box)

There is a wrapper shell script for the ISO to OVF stage, mainly to set the Ubuntu mirrors statically
before kicking off packer.

The second stage can be executed directly by calling packer:

packer build ubuntu_ovf_to_box.json
