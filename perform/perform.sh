#!/bin/bash
#########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0 Unless required by
## applicable law or agreed to in writing, software distributed under the
## License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
## CONDITIONS OF ANY KIND, either express or implied. See the License for
## the specific language governing permissions and limitations under the
## License.
##
########################################################################

########################################################################
##
##   Description:
##     A simple shell script to run some RDMA performance testing on
##     iomem, GPU mem and or main memory.
##
########################################################################

  # Notes from Logan

# The command I'm using on the server is:
#
#  > likwid-perfctr -g MEM -C S0:0 ib_write_bw -R -s 8388608
#
# On the client it's just
#
#  > ib_write_bw -s 8388608 -R -n 1024 donard-rdma
#
# * Add -mmap <whatever> (w/ sudo) and the memory use goes up a little bit
# * To do cross-socket tests change -C S0:0 to -C S1:0
# * Similar results with ib_read_bw instead of ib_write_bw
# * I think -R is probably optional
#
# I've done a few tests and once we are running on the same socket things seem to make a lot more sense.


  # Parameters for running the performance code
EXE=ib_write_bw
ARGS="-D 30 -s 8388608"
SERVER=donard-rdma
CLIENT=192.168.5.143
USER=batesste
BAR=/sys/bus/pci/devices/0000:00:03.0/0000:03:00.0/resource4
PERF="likwid-perfctr"
PARGS="-g MEM -C S0:0"
LOG="perform.log"

  # Accept some key parameter changes from the command line.
while getopts "e:a:s:c:" opt; do
    case "$opt" in
	e)  EXE=${OPTARG}
            ;;
	a)  ARGS=${OPTARG}
            ;;
	s)  SERVER=${OPTARG}
            ;;
	c)  CLIENT=${OPTARG}
            ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
	    ;;
    esac
done

  # Perform some error checking
TMP=$(which ${EXE})
if [ ! -x ${TMP} ] ; then
    echo "ERROR: Could not find ${EXE} on path. You can point to it using the -e option."
    exit -1
fi
TMP=$(which ${PERF})
if [ ! -x ${TMP} ] ; then
    echo "ERROR: Could not find ${PERF} on path. Please fix this and then re-run."
    exit -1
fi

  # Run the performance test on the server and then use ssh to run the
  # command on the client side.

run_test() {
    ${PERF} ${PARGS} ${EXE} ${ARGS} &
    ssh ${USER}@${CLIENT} ${EXE} ${ARGS} ${SERVER}

    ${PERF} ${PARGS} ${EXE} ${ARGS} -mmap=${BAR} &
    ssh ${USER}@${CLIENT} ${EXE} ${ARGS} ${SERVER}
}

run_test | tee ${LOG}
