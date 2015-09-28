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
GitHub repo. i.e. git clone
https://github.com/sbates130272/linux-donard.git. For a view of how
this kernel is constructed see linux-donard.pdf.

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
   https://wiki.debian.org/NvidiaGraphicsDrivers. Note that several
   people have has issues with this step and tieing the Nvidia code
   into the nvme_donard module. So we outline a more complete
   procedure in the next section.

## Installation - Nvidia code and nvme_donard (thanks Jack ;-))

1. Build ubuntu 14.04.3 server on the system

2. apt-get install git kernel-package, libncurses5-dev fakerootbzip2 bc

3. git clone https://github.com/sbates130272/linux-donard.git.
  1. apt-get update followed by apt–get upgrade
  2. cd to linux-donard directory
  3. make-kpkg clean
  4. fakeroot make-kpkg —initrd --append-to-version=-docker-donard
  kernel_image kernel_headers (Accept defaults from pmem and DAX).
  5. cd ..
  6. (As root) dpkg -I *donard*.deb
  7. Reboot
  8. uname -r to verify kernel loaded

4. Check soft links
  1. /lib/modules/3.19.1-docker-donard+/build and
  /lib/modules/3.19.1-docker-donard+/source should point to
  /usr/src/linux-headers-3.19.1-docker-donard+

5. Load latest cuda package from nvidia

6. As root
  1. Copy .deb file from https://developer.nvidia.com/cuda-downloads
  2. dpkg –I cuda*.deb
  3. apt-get update
  4. Apt-get install cuda
  5. Export PATH and library variables
  6. Driver will be installed  in /usr/src/nvidia-352-352.39 for cuda
  7.5
  7. cd to nvidia src directory

6. As root, not sudo
  1. kernelver=$(uname –r)
  2. kernel_source_dir=/lib/modules/$kernelver/build
  3. make module KERNDIR=/lib/modules/$kernelver \
     IGNORE_XEN_PRESENCE=1 IGNORE_CC_MISMATCH=1 \
     SYSSRC=$kernel_source_dir LD=/usr/bin/ld.bfd

7. Verify Module.symvers is built in nvidia src directory

8. Build Donard components
  1. cd to home
  2. git clone —recursive https://github.com/sbates130272/donard.git
  3. cd to donard/nvme_donard directory
  4. Edit Makefile to point to correct nvidia src directory
  5. Run make install as root
  6. lsmod |grep nvme_donard

9. If module not visible then
  1. modprobe nvme_donard

10. Build and run tests
  2. May have to make modules followed by make install
  3. cd donard/libargconfig
  4. Execute ./waf , may have to ./waf install
  5. cd to donard/libdonard
  6. apt-get install libfftw3-dev libmagickwand-dev
  7. ./waf
  8. modprobe donard_nv_pinbuf
  9. mkdir /temp
  10. mkfs.ext4 /dev/nvme0n1
  11. mount /dev/nvme0n1 /temp
  12. dd if=/dev/zero of=/temp/test1.dat bs=1K count=100K
  13. cd donard/libdonard/build/speed
  14. ./nvme2gpu_read -b 128M -D /temp/test1.dat
  15. ./nvme2gpu_read -b 128M  /temp/test1.dat

### Example output
~/donard/libdonard/build/speed# ./nvme2gpu_read -b 128M /temp/test1.dat
  Total CPU Time: 0.0s user, 0.9s system
  Page Faults: 9
Copied 104.86MB in 348.6 ms   300.78MB/s

~/donard/libdonard/build/speed# ./nvme2gpu_read -b 128M -D /temp/test1.dat
  Total CPU Time: 0.1s user, 0.9s system
  Page Faults: 1607

Copied 104.86MB in 80.9  ms     1.30GB/s

## Quick Start - NVMe<->GPU

1. cd <root>/nvme_donard
2. make install (this loads the nvme_donard kernel module and blacklists the defult nvme one).
3. lsmod | grep nvme should return nvme_donard (and not nvme).
4. cd <root>/libdonard
5. ./waf
6. cd <root>/libdonard/build/speed
7. dd if=/dev/zero of=/\<nvme_drive\>/test1.dat bs=1K count=100K (to create a test file, for now keep it at 128MB or less)
8. ./nvme2gpu_read  -b 128M -D /\<nvme_drive\>/test1.dat
9. ./nvme2gpu_read  -b 128M =/\<nvme_drive\>/test1.dat


If all of this runs you should see the –D mode has WAY more page
faults the without the –D (the non –D is p2p, with –D the transfer
goes via DRAM). Depending on your system the non –D option may be
faster too. This is nvme->gpu transfer. There is a similar executable
in the same fodler to go the other way. You can use likwid-perfctr to
get better memory and CPU measurements too.

## Quick Start - perform.sh

A simple bash script resides in the perform folder. When run it checks
for certain files on the path and then executes a client/server
perftest test whilst tracking DRAM bandwidth on the server.

## Quick Start - NVDIMMs

We have some code in here to test NVDIMMs and the IOMEM exposed in the
PMC Flashtec NVRAM drive. You can also use it to test any memory
region really. Anyway here are some steps for the NVDIMM...

1. git clone --recursive https://github.com/sbates130272/donard.git pulls the code.
2. cd donard/libargconfig
3. sudo ./waf install
4. cd ../..
5. cd donard/nvram_bench
6. ./waf (builds the code, should be no errors).
7. Since our kernel has the PMEM+DAX patches we can setup the NVDIMM but adding the following line to /etc/modules:
   pmem pmem_start_gb=8 pmem_size_gb=8
8. The NVDIMM appears as a /dev/pmem\<num\> and we can mount it using the following in /etc/fstab:
   /dev/pmem\<num\>      /mnt/nvdimm     ext4    dax,noatime   0  0
9. You can now run the nvdimm.sh script on the nvdimm.

## Quick Start - RDMA

For these tests you will need two machines (a server and a client) and
the donard kernel and OFED drivers on both machines. Each machine will
also need a OFED compliant NIC installed. We've done some testing on
both the Chelsio T540-CR iWARP card and the Mellanox MT27600 IB card.

### Server

1. git clone --recursive https://github.com/sbates130272/donard.git pulls the code.
2. cd donard/donard_rdma
3. ./waf
4. Run the server (three modes available):
i. ./build/donard_rdma_server (runs in main memory)
ii. ./build/donard_rdma_server -g (runs in a bar on GPU)
iii. ./build/donard_rdma_server -m <file> (runs in a mmap of the
specified file. If that file is on a NVRAM card it will use that and
do p2p).
4. Run the client (see below). When the client runs you should see
somethng like the following on the server:

Buffer Type: CPU
Listening on port 11935

Buffer Created: 0x7fa8040a6010 length 1024kB
Accepting Client Connection: 172.16.0.2
Testing Send/Recv
Send Completed Successfully.
Recv Completed Succesfully.
Got Seed 220246839, length 32768, use_zeros 0
Buffer Matches Random Seed.
Client Disconnected.


### Client

1. git clone --recursive https://github.com/sbates130272/donard.git pulls the code.
2. cd donard/donard_rdma
3. ./waf
4. ./build/donard_rdma_client -a <address> -w (note address will be
system specific and in our case is donard-rdma)
5. If things work as expected you should get something like:

batesste@cgy1-flash:~/donard/donard_rdma$ donard_rdma_client -a
donard-rdma
Seed: 1422379394
rdma_connect: Connection refused
batesste@cgy1-flash:~/donard/donard_rdma$ donard_rdma_client -a
donard-rdma -w
Seed: 1422379414
Remote Buffer: 0x7fa8040a6010 : length 1024KiB : bs = 32768B
Testing Send/Recv
Recv Completed Succesfully.
Send Completed Successfully.

Testing Writes

Wrote:        8MiB
Transfered:   8.42MB in 0.0s   281.21MB/s

## References

A good place to get started is the [Flash Memory
Summit](www.flashmemorysummit.com) 2013
[paper](http://www.flashmemorysummit.com/cgi-bin/start.cgi/HTMLOS_Pages/Entrance_Proceedings.html)
that discusses Donard. Another reference is the article on
[PMC-Sierra's
blog](http://blog.pmcs.com/project-donard-peer-to-peer-communication-with-nvm-express-devices-part-1/)

## Licensing

This code is licensed under Apache Version 2.0 and, where required, GPL Version 2.0
