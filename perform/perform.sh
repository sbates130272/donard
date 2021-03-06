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


  # Parameters for running the performance code
EXE=ib_write_bw
ARGS="-R -D 5 -s 8388608"
SERVER=donard-rdma
CLIENT=192.168.5.143
BAR=/sys/bus/pci/devices/0000:00:03.0/0000:03:00.0/resource4
PERF="likwid-perfctr"
PARGS="-g MEM -C S0:0"
LOG="perform.log"
MEM=mbw
MARGS="-n 0 -t 0 1024"

  # Pre-authenticate with sudo to prevent the background processes below
  # from going nuts.
sudo -v

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
TMP=$(which ${MEM})
if [ ! -x ${TMP} ] ; then
    echo "ERROR: Could not find ${MEM} on path. Please fix this and then re-run."
    exit -1
fi

  # Run the performance test on the server and then use ssh to run the
  # command on the client side.

cleanup() {
    kill ${MEM_PID}
}

run_test() {
    taskset -c 1 ${MEM} ${MARGS} &> memory.log &
    MEM_PID=$!
    trap cleanup EXIT

    sudo ${PERF} ${PARGS} ${EXE} ${ARGS} --mmap=${BAR} &
    SERVER_PID=$!
    sleep 2
    ssh ${CLIENT} ${EXE} ${ARGS} ${SERVER} &> /dev/null
    wait $SERVER_PID || exit 1

    sudo ${PERF} ${PARGS} ${EXE} ${ARGS} &
    SERVER_PID=$!
    sleep 2
    ssh ${CLIENT} ${EXE} ${ARGS} ${SERVER} &> /dev/null
    wait $SERVER_PID || exit 1

}

run_test | tee ${LOG}
