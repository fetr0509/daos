#!/bin/bash

set -ex -o pipefail

# shellcheck disable=SC1091
if [ -f .localenv ]; then
    # read (i.e. environment, etc.) overrides
    . .localenv
fi

HOSTPREFIX=${HOSTPREFIX-"wolf-53"}
NFS_SERVER=${NFS_SERVER:-$HOSTPREFIX}

trap 'echo "exited with error"' ERR

# put yaml files back
restore_dist_files() {
    local dist_files="$*"

    for file in $dist_files; do
        if [ -f "$file".dist ]; then
            mv -f "$file".dist "$file"
        fi
    done

}

# shellcheck disable=SC1091
. .build_vars.sh

#yum install python2-avocado.noarch                               \
#            python2-avocado-plugins-output-html.noarch           \
#            python2-avocado-plugins-varianter-yaml-to-mux.noarch \
#            python2-aexpect.noarch

# set our machine names
#yaml_files=($(find . -name \*.yaml))
mapfile -t yaml_files < <(find src/tests/ftest -name \*.yaml)

# shellcheck disable=SC2086
sed -i.dist -e "s/- boro-A/- ${HOSTPREFIX}vm1/g" \
            -e "s/- boro-B/- ${HOSTPREFIX}vm2/g" \
            -e "s/- boro-C/- ${HOSTPREFIX}vm3/g" \
            -e "s/- boro-D/- ${HOSTPREFIX}vm4/g" \
            -e "s/- boro-E/- ${HOSTPREFIX}vm5/g" \
            -e "s/- boro-F/- ${HOSTPREFIX}vm6/g" \
            -e "s/- boro-G/- ${HOSTPREFIX}vm7/g" \
            -e "s/- boro-H/- ${HOSTPREFIX}vm8/g" "${yaml_files[@]}"

trap 'set +e; restore_dist_files "${yaml_files[@]}"' EXIT

# let's output to a dir in the tree
rm -rf src/tests/ftest/avocado ./*_results.xml
mkdir -p src/tests/ftest/avocado/job-results

DAOS_BASE=${SL_OMPI_PREFIX%/install}
if ! pdsh -R ssh -S -w "${HOSTPREFIX}"vm[1-8] "set -ex
ulimit -c unlimited
if grep /mnt/daos\\  /proc/mounts; then
    sudo umount /mnt/daos
else
    if [ ! -d /mnt/daos ]; then
        sudo mkdir -p /mnt/daos
    fi
fi
sudo mkdir -p $DAOS_BASE
sudo mount -t nfs $NFS_SERVER:$PWD $DAOS_BASE
sudo mount -t tmpfs -o size=16G tmpfs /mnt/daos
rm -rf /tmp/Functional_${1:-quick}/
mkdir -p /tmp/Functional_${1:-quick}/" 2>&1 | dshbak -c; then
    echo "Cluster setup (i.e. provisioning) failed"
    exit 1
fi

# shellcheck disable=SC2154
trap 'set +e
restore_dist_files "${yaml_files[@]}"
pdsh -R ssh -S -w ${HOSTPREFIX}vm[1-8] "sudo umount /mnt/daos
x=0
while [ \$x -lt 30 ] &&
      grep $DAOS_BASE /proc/mounts &&
      ! sudo umount $DAOS_BASE; do
    sleep 1
    let x=\$x+1
done
sudo rmdir $DAOS_BASE" 2>&1 | dshbak -c' EXIT

# shellcheck disable=SC2029
if ! ssh "${HOSTPREFIX}"vm1 "set -ex
rm -rf $DAOS_BASE/install/tmp
mkdir -p $DAOS_BASE/install/tmp
cd $DAOS_BASE
export CRT_ATTACH_INFO_PATH=$DAOS_BASE/install/tmp
export DAOS_SINGLETON_CLI=1
export CRT_CTX_SHARE_ADDR=1
export CRT_PHY_ADDR_STR=ofi+sockets
export ABT_ENV_MAX_NUM_XSTREAMS=64
export ABT_MAX_NUM_XSTREAMS=64
export OFI_INTERFACE=eth0
export OFI_PORT=23350
# At Oct2018 Longmond F2F it was decided that per-server logs are preferred
# But now we need to collect them!
export DD_LOG=/tmp/Functional_${1:-quick}/daos.log
export D_LOG_FILE=/tmp/Functional_${1:-quick}/daos.log
export D_LOG_MASK=DEBUG,RPC=ERR,MEM=ERR

pushd src/tests/ftest

mkdir -p ~/.config/avocado/
cat <<EOF > ~/.config/avocado/avocado.conf
[datadir.paths]
logs_dir = $DAOS_BASE/src/tests/ftest/avocado/job-results
EOF

# nowrun it!
if ! ./launch.py \"${1:-quick}\"; then
    rc=${PIPESTATUS[0]}
else
    rc=0
fi
ls -l
exit \$rc"; then
    rc=${PIPESTATUS[0]}
else
    rc=0
fi

# collect the logs
if ! rpdcp -R ssh -w "${HOSTPREFIX}"vm[1-8] \
    /tmp/Functional_"${1:-quick}"/\*daos.log "$PWD"/; then
    echo "Copying daos.logs from remote nodes failed"
    # pass
fi
ls -l
exit "$rc"