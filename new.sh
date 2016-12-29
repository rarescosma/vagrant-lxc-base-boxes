#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

if [ "$(id -u)" != "0" ]; then
  echo "You should run this script as root (sudo)."
  exit 1
fi

export DISTRIBUTION='ubuntu'
export RELEASE='xenial'
export ARCH=$(uname -m | sed -e "s/68/38/" | sed -e "s/x86_64/amd64/")
export CONTAINER="$1"

export ADDPACKAGES=${ADDPACKAGES-$(cat ${RELEASE}_packages | tr "\n" " ")}

export ROOTFS="/var/lib/lxc/${CONTAINER}/rootfs"
export WORKING_DIR="/tmp/${CONTAINER}"
export NOW=$(date -u)
export LOG=$(readlink -f .)/log/${CONTAINER}.log
export THE_USER=${THE_USER:-"ubuntu"}
RAND=`shuf -i 10-200 -n 1`
export THE_IP=${THE_IP:-"10.5.0.$RAND"}
export THE_GATEWAY=${THE_GATEWAY:-"10.5.0.2"}

mkdir -p $(dirname $LOG)
echo '############################################' > ${LOG}
echo "# Beginning build at $(date)" >> ${LOG}
touch ${LOG}
chmod +rw ${LOG}
mkdir -p ${WORKING_DIR}

# Step 1. Build the container
info "Building '${CONTAINER}'' box..."
./common/create.sh
./common/configure-network.sh
./debian/lxc-fixes.sh
./debian/prepare-user.sh
./debian/install-extras.sh
./debian/clean.sh
info "Finished building '${CONTAINER}'!"
echo

# Step 2. Enable sharing from /srv/${CONTAINER}
mkdir -p /srv/${CONTAINER}
find /srv/${CONTAINER} -type d -exec chmod 2775 {} \;
find /srv/${CONTAINER} -type d -exec chown root:wheel {} \;
append "/srv/${CONTAINER}  /var/lib/lxc/${CONTAINER}/rootfs/srv  none  bind,create=dir" /etc/fstab
mount | grep /srv/${CONTAINER} || mount /srv/${CONTAINER}

# Step 3. Configure salt
log "Configuring the salt minion."
cat << EOF | sudo tee $ROOTFS/etc/salt/minion >/dev/null 2>/dev/null
id: dev-${CONTAINER}-vm
environment: dev
file_client: local
file_roots:
  dev:
    - /srv/platform
pillar_roots:
  dev:
    - /srv/platform/_pillar
cache_jobs: True
grains:
  somc_env: dev
state_output: mixed
EOF

log "Restarting the minion."
utils.lxc.attach service salt-minion restart
utils.lxc.attach salt-call --local state.highstate

# Step 4. Highstate
