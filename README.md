packer-ubuntu-virtualbox
========================

Packer templates for Ubuntu on Virtualbox for Vagrant (2 Stage - ISO to OVF, then OVF to Vagrant Box)

Both stages have wrapper shell scripts, for the ISO to OVF stage this is to set the Ubuntu mirrors statically
before kicking off packer. For the OVF to Vagrant Box stage, we find the most recent OVF in the directory
and pass it to packer.

By default these scripts will build for Ubuntu Precise 12.04, see below for details on building other versions.

# Motive

This repo exists primarily due to VirtualBox not accepting the Ubuntu provided OVF files, issue documented at https://github.com/mitchellh/packer/issues/1726
The implementation here works around the issue.

# Prerequisites

These scripts assume you have the below available/installed:

- Bash (3.x upwards)
- Packer (tested on 0.7.5 / OSX)
- VirtualBox (tested on 4.3.20 / OSX)

And to test boxes:

- Vagrant (tested on 1.7.1 / OSX)

My testing was done on OSX 10.9.5, but the logic should work on most operating systems. Unsure about Windows mainly due to paths though.

# Quick-Start Guide

Create a file called cdimages_mirror.txt in this directory, copy one of the 'http' links from https://launchpad.net/ubuntu/+cdmirrors. Use a trailing slash and make it a one line file.

Then, run the below, which will pick the first mirror from mirrors.ubuntu.com/mirrors.txt, inject it and start packer:

```bash
./start_iso_to_ovf.sh precise|trusty|xenial|bionic
```

(Ensure you pick a single OS version as the single argument specified above)

The result of the above will be a directory called output-virtualbox-iso/ containing a .ovf and .vmdk file.

Next start building a Vagrant Box by running:

```bash
./start_ovf_to_box.sh
```

It will use the latest generated OVF file in the above output directory. The result here will be a Vagrant Box file that can be added to Vagrant using:

```bash
vagrant box add packer_virtualbox-ovf_virtualbox.box
```

# Changing Ubuntu Version

You can modify the versions specified at the top of start_iso_to_ovf.sh to build for Trusty or any other versions accordingly.

# Customizing your Vagrant Boxes

If you modify scripts/ubuntu_box_setup.sh you can add any custom logic to the existing shell provisioner at the bottom.

Alternatively you can modify ubuntu_ovf_to_box_template.json and add extra provisioners to build your box.

# Credits

[Jeff Geerling](https://github.com/geerlingguy/packer-ubuntu-1804) implemented a good Packer `virtualbox-iso` template for Ubuntu 18.04 which was partially used here.
