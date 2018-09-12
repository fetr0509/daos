#!/bin/bash

set -ex

TESTS=${1:-"-mpceiACoRO"}

# shellcheck disable=SC1091
if [ -f .localenv ]; then
    # read (i.e. environment, etc.) overrides
    . .localenv
fi

HOSTPREFIX=${HOSTPREFIX-"wolf-53"}
NFS_SERVER=${NFS_SERVER:-$HOSTPREFIX}

# leave this empty to run on the centos7 builder
CLIENT_VM=${HOSTPREFIX}vm1

# shellcheck disable=SC1091
. .build_vars.sh

daospath=${SL_OMPI_PREFIX%/install}
CPATH="${daospath}"/install/include/:"$CPATH"
PATH="${daospath}"/install/bin/:"${daospath}"/install/sbin:"$PATH"
LD_LIBRARY_PATH="${daospath}"/install/lib:"${daospath}"/install/lib/daos_srv:$LD_LIBRARY_PATH
export CPATH PATH LD_LIBRARY_PATH
export CRT_PHY_ADDR_STR="ofi+sockets"

cat <<EOF > hostfile
${HOSTPREFIX}vm1 slots=1
${HOSTPREFIX}vm2 slots=1
${HOSTPREFIX}vm3 slots=1
${HOSTPREFIX}vm4 slots=1
${HOSTPREFIX}vm5 slots=1
${HOSTPREFIX}vm6 slots=1
${HOSTPREFIX}vm7 slots=1
${HOSTPREFIX}vm8 slots=1
EOF

# shellcheck disable=SC1091
#. scons_local/utils/setup_local.sh

export SERVER_OFI_INTERFACE=eth0
if [ -n "$CLIENT_VM" ]; then
    export CLIENT_OFI_INTERFACE=eth0
else
    export CLIENT_OFI_INTERFACE=virbr1
fi

# memory requirements of servers
REQ_MEMORY=0
if [[ $TESTS = *r* ]]; then
    # only approximate for now
    REQ_MEMORY=10000000
fi
pdsh -R ssh -S -w "${HOSTPREFIX}"vm[1-8] "sudo bash -c 'echo \"1\" > /proc/sys/kernel/sysrq'
# this all, including the creation of the mock results.xml is a big hack
# until daos_test is properly skipping subtests (or whole suites with a
# skip for each subtest) where there is not enough memory: DAOS-1454
set -x
MEMORY=\$(sed -ne '/MemTotal:/s/.*: *\\([0-9][0-9]*\\).*/\\1/p' /proc/meminfo)
if [ \"\$MEMORY\" -lt \"$REQ_MEMORY\" ]; then
    exit 1
fi
if grep /mnt/daos\\  /proc/mounts; then
    sudo umount /mnt/daos
else
    if [ ! -d /mnt/daos ]; then
        sudo mkdir -p /mnt/daos
    fi
fi
sudo mkdir -p $daospath
sudo mount -t nfs $NFS_SERVER:$PWD $daospath
sudo mount -t tmpfs -o size=16G tmpfs /mnt/daos
df -h /mnt/daos" 2>&1 | dshbak -c
# see above re: DAOS-1454
# note that the number of test and subtest names in the XML
# below needs to be kept in sync with src/tests/suite/daos_rebuild.c
rc="${PIPESTATUS[0]}"
if [ "$rc" -eq 1 ]; then
    echo "Servers don't have enough memory, faking subtest skips (DAOS-1454)"
    cat <<EOF > "${daospath}"/results.xml
<?xml version="1.0" encoding="UTF-8" ?>
<testsuites>
  <testsuite name="DAOS rebuild tests" time="0" tests="1" failures="0" errors="0" skipped="33">
    <testcase name="REBUILD1: rebuild small rec mulitple dkeys" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD2: rebuild small rec multiple akeys" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD3: rebuild small rec multiple indexes" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD4: rebuild small rec multiple keys/indexes" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD5: rebuild large rec single index" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD6: rebuild multiple objects" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD7: drop rebuild scan reply" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD8: retry rebuild for not ready" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD9: drop rebuild obj reply" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD10: rebuild multiple pools" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD11: rebuild update failed" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD12: retry rebuild for pool stale" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD13: rebuild with container destroy" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD14: rebuild with container close" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD15: rebuild with pool destroy during scan" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD16: rebuild with pool destroy during rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD17: rebuild iv tgt fail" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD18: rebuild tgt start fail" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD19: rebuild send objects failed" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD20: rebuild with master change during scan" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD21: rebuild with master change during rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD22: rebuild no space failure" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD23: rebuild multiple tgts" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD24: disconnect pool during scan" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD25: disconnect pool during rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD26: connect pool during scan for offline rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD27: connect pool during rebuild for offline rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD28: offline rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD29: rebuild with master failure" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD30: rebuild with two failures" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD31: rebuild fail all replicas before rebuild" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD32: rebuild fail all replicas" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
    <testcase name="REBUILD33: multi-pools rebuild concurrently" time="0">
      <skipped message="Not enough memory on one ore more servers"/>
    </testcase>
  </testsuite>
</testsuites>
EOF
    exit 0
elif [ "$rc" -ne 0 ]; then
    echo "Error preparing nodes for running the DAOS server"
    exit "$rc"
fi

rm -f "${daospath}"/daos.log

# shellcheck disable=SC2029
ssh "$CLIENT_VM" "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
\"${daospath}\"/install/bin/orterun --np 8 --hostfile \"$daospath\"/hostfile --enable-recovery --report-uri \"$daospath\"/urifile  -x LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\" -x CRT_PHY_ADDR_STR=\"$CRT_PHY_ADDR_STR\" -x D_LOG_FILE=\"$daospath\"/daos.log -x ABT_ENV_MAX_NUM_XSTREAMS=100 -x ABT_MAX_NUM_XSTREAMS=100 -x PATH=\"$PATH\" -x OFI_PORT=23350 -x OFI_INTERFACE=\"$SERVER_OFI_INTERFACE\" \"${daospath}\"/install/bin/daos_server -g daos_server -c 1 >/tmp/daos_server.out 2>&1 &
daos_server_pid=\$!
if ! kill -0 \$daos_server_pid 2>/dev/null; then
    wait \$daos_server_pid
    exit \${PIPESTATUS[0]}
else
    echo \"\$daos_server_pid\" > /tmp/daos_server_pid
fi"
# shellcheck disable=SC2154
trap 'ssh "$CLIENT_VM" "daos_server_pid=\$(cat /tmp/daos_server_pid)
if kill -0 \$daos_server_pid 2>/dev/null; then
    kill \$daos_server_pid
fi"
pdsh -R ssh -S -w ${HOSTPREFIX}vm[1-8] "x=0
while [ \$x -lt 30 ] && grep $daospath /proc/mounts && ! sudo umount $daospath; do
    sleep 1
    let x=\$x+1
done
sudo rmdir $daospath" 2>&1 | dshbak -c
ls -l "$daospath"/daos.log' EXIT

sleep 5

# shellcheck disable=SC2029
if ! ssh "$CLIENT_VM" "daos_server_pid=\$(cat /tmp/daos_server_pid)
    if ! kill -0 \$daos_server_pid 2>/dev/null; then
        exit 199
    fi
    # cmocka's XML results are not JUnit compliant as it creates multiple
    # <testsuites> blocks and only one is allowed
    # https://gitlab.com/cmocka/cmocka/issues/5
    trap 'set -x; sed -i -e '\"'\"'2!{/<testsuites>/d;}'\"'\"' -e '\"'\"'\$!{/<\\/testsuites>/d;}'\"'\"' \"${daospath}\"/results.xml' EXIT
    rm -f \"${daospath}\"/results.xml
    CMOCKA_XML_FILE=\"${daospath}\"/results.xml CMOCKA_MESSAGE_OUTPUT=xml \"${daospath}\"/install/bin/orterun --output-filename \"$daospath\"/daos_test.out --np 1 --ompi-server file:\"$daospath\"/urifile -x ABT_ENV_MAX_NUM_XSTREAMS=100 -x PATH=\"$PATH\" -x CRT_PHY_ADDR_STR=\"$CRT_PHY_ADDR_STR\" -x ABT_MAX_NUM_XSTREAMS=100 -x LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\" -x D_LOG_FILE=\"$daospath\"/daos.log -x OFI_INTERFACE=\"$CLIENT_OFI_INTERFACE\" daos_test \"$TESTS\""; then
    if [ "${PIPESTATUS[0]}" = 199 ]; then
        echo "daos_server not running"
        pdsh -R ssh -S -w "${HOSTPREFIX}"vm[1-8] "if [ -f /tmp/daos_server.out ]; then cat /tmp/daos_server.out; fi" | dshbak -c
        trap 'pdsh -R ssh -S -w ${HOSTPREFIX}vm[1-8] "x=0
while [ \$x -lt 30 ] && grep $daospath /proc/mounts && ! sudo umount $daospath; do
    sleep 1
    let x=\$x+1
done
sudo rmdir $daospath" 2>&1 | dshbak -c' EXIT
        exit 199
    else
        echo "Running daos_test failed"
        exit 1
    fi
fi
