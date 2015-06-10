#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

PLATFORM='/srv/gits/platform'

salt.lxc.attach() {
  cmd="$@"
  log "Running [${cmd}] inside '${CONTAINER}' container clearly..."
  (lxc-attach -n ${CONTAINER} --clear-env -- $cmd) &>> ${LOG}
}

# Install some packages upfront to shorten the highstate run
PACKAGES=(libfontconfig1-dev git-core rsync htop silversearcher-ag supervisor s3cmd graphicsmagick)
utils.lxc.attach apt-get install ${PACKAGES[*]} -y --force-yes

# Pre-install binary ruby
mkdir -p ${ROOTFS}/opt/rubies
tar zxf ${PLATFORM}/preseed/ruby-2.1.4.tgz -C ${ROOTFS}/opt/rubies

# Sync the state tree and the minion config to the lxc container
rsync -avz ${PLATFORM}/salt/ ${ROOTFS}/srv/salt/
cp -f ${PLATFORM}/devbox/basebox/minion_config ${ROOTFS}/etc/salt/minion

# Run the pre-provisioning highstate
cat > ${ROOTFS}/tmp/salt.sh << EOF
#!/bin/bash
source /etc/profile
export HOME=/home/vagrant

# Sync custom grains
salt-call --local saltutil.sync_all

# To avoid the stdin nonsense run highstate in the background
salt-call --local state.highstate &
wait
chown -R vagrant:vagrant /home/vagrant
EOF

chmod +x ${ROOTFS}/tmp/salt.sh
salt.lxc.attach /tmp/salt.sh
rm -rf ${ROOTFS}/srv/salt
