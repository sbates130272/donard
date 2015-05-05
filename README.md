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
   https://wiki.debian.org/NvidiaGraphicsDrivers.

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
