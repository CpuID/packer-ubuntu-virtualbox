packer-ubuntu-virtualbox
========================

Packer templates for Ubuntu on Virtualbox for Vagrant (2 Stage - ISO to OVF, then OVF to Vagrant Box)

Both stages have wrapper shell scripts, for the ISO to OVF stage this is to set the Ubuntu mirrors statically
before kicking off packer. For the OVF to Vagrant Box stage, we find the most recent OVF in the directory
and pass it to packer.

# Usage Guide

The below will pick the first mirror from mirrors.ubuntu.com/mirrors.txt and inject it:

```bash
./start_iso_to_ovf.sh
```

The result of the above will be a directory called output-virtualbox-iso/ containing a .ovf and .vmdk file.

Next, by running:

```bash
./start_ovf_to_box.sh
```

The result here will be a Vagrant Box file that can be added to Vagrant using:

```bash
vagrant box add TODO-filename
