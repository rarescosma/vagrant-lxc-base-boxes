#!/bin/bash
set -e

sudo PUPPET=0 CHEF=0 SALT=1 BABUSHKA=0 make trusty
