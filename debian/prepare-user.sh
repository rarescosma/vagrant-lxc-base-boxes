#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

info "Preparing the user..."

utils.lxc.attach /opt/prepare-user.sh $THE_USER
