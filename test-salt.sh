#!/bin/bash
set -e

source common/ui.sh

if [ "$(id -u)" != "0" ]; then
  echo "You should run this script as root (sudo)."
  exit 1
fi

export DISTRIBUTION='ubuntu'
export RELEASE='trusty'
export ARCH='amd64'
export CONTAINER='vagrant-base-trusty-amd64'
export PACKAGE='output/vagrant-lxc-rc.box'
export ROOTFS="/var/lib/lxc/${CONTAINER}/rootfs"
export WORKING_DIR="/tmp/${CONTAINER}"
export NOW=$(date -u)
export LOG=$(readlink -f .)/log/${CONTAINER}.log

mkdir -p $(dirname $LOG)
touch ${LOG}
chmod +rw ${LOG}

debug "Creating ${WORKING_DIR}"
mkdir -p ${WORKING_DIR}

./somc/salt.sh ${CONTAINER}
