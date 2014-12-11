# Donard

## Summary

Donard: A PCIe Peer-2-Peer Library that builds on top of NVM Express

## Code Structure

The Donard repo is really just a container for a multiple of smaller
git repos. See of them in turn for their README and licensing
information.

## Installation

1. Start from your Linux distro of choice on a bare-metal machine. You
could try running this inside a VM but since we need to access
bare-metal I am not sure why you would. We used Debian Wheezy as a
start point but we have made many mods from there.

2. Install the packages required to install a updated Linux kernel. At
a minimum you are going to need the following
packages. kernel-package, libncurses5-dev, fakeroot, bzip2 and bc.

3. Clone the Donard version of the linux kernel from the relevant
GitHub repo. i.e. git clone https://github.com/sbates130272/linux-donard.git

4. Build and install this version of the linux kernel.
   cd linux-donard
   make-kpkg clean
   fakeroot make-kpkg --initrd --append-to-version=-docker-donard kernel_image kernel_headers
   cd ..
   dpkg -i linux-image-3.16.3-docker-donard+_3.16.3-docker-donard+-10.00.Custom_amd64.deb
   dpkg -i linux-headers-3.16.3-docker-donard+_3.16.3-docker-donard+-10.00.Custom_amd64.deb

5. Now pull the rest of the donard project code:
   git clone https://github.com/sbates130272/donard.git

6. Install the Nvidia driver. We used the instructions at
   https://wiki.debian.org/NvidiaGraphicsDrivers.

## Quick Start - NVMe<->GPU

1. cd <root>/nvme_donard
2. make install (this loads the nvme_donard kernel module and blacklists the defult nvme one).
3. lsmod | grep nvme should return nvme_donard (and not nvme).
4. cd <root>/libdonard
5. ./waf
6. cd <root>/libdonard/build/speed
7. dd if=/dev/zero of=/<nvme_drive>/test1.dat bs=1K count=100K (to create a test file, for now keep it at 128MB or less)
8. ./nvme2gpu_read  -b 128M -D /<nvme_drive>/test1.dat
9. ./nvme2gpu_read  -b 128M =/<nvme_drive>/test1.dat


If all of this runs you should see the –D mode has WAY more page
faults the without the –D (the non –D is p2p, with –D the transfer
goes via DRAM). Depending on your system the non –D option may be
faster too. This is nvme->gpu transfer. There is a similar executable
in the same fodler to go the other way. You can use likwid-perfctr to
get better memory and CPU measurements too.

## References

A good place to get started is the [Flash Memory
Summit](www.flashmemorysummit.com) 2013
[paper](http://www.flashmemorysummit.com/cgi-bin/start.cgi/HTMLOS_Pages/Entrance_Proceedings.html)
that discusses Donard. Another reference is the article on
[PMC-Sierra's
blog](http://blog.pmcs.com/project-donard-peer-to-peer-communication-with-nvm-express-devices-part-1/)

## Licensing

This code is licensed under Apache Version 2.0 and, where required, GPL Version 2.0
