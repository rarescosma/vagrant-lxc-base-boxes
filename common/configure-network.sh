#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

CONFIG_FILE=/var/lib/lxc/${CONTAINER}/config

if [ ${DISTRIBUTION} = 'ubuntu' ]
then
  SCRIPTPATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  mkdir -p $ROOTFS/opt
  cp $SCRIPTPATH/../debian/opt/*.sh $ROOTFS/opt
  chmod +x $ROOTFS/opt/*.sh

  if grep --quiet veth $CONFIG_FILE; then
    log "Skipping network configuration..."
  else
    warn "Network not configured. Configuring and restarting container..."
    TEMP_FILE=${WORKING_DIR}/ubuntu-network-config
    RESOLV_ROOT=${ROOTFS}/etc/resolvconf/resolv.conf.d

    sed -e '/lxc.network.type = empty/ s/^#*/#/' -i $CONFIG_FILE
    cp $SCRIPTPATH/../conf/ubuntu-network $TEMP_FILE
    sed -e "s/<THE_IP>/${THE_IP}/" -e "s/<THE_GATEWAY>/${THE_GATEWAY}/" -i $TEMP_FILE
    cat $TEMP_FILE >> $CONFIG_FILE

    utils.lxc.stop

    cp -p $RESOLV_ROOT/head $RESOLV_ROOT/head.bak
    echo "nameserver 8.8.8.8" > $RESOLV_ROOT/head
    echo "nameserver 8.8.4.4" >> $RESOLV_ROOT/head

    utils.lxc.start
  fi
fi
