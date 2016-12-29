#!/bin/bash

THE_USER=$1
export SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3HL2xCH+61ne4fhmA4Io2XkgNsATqF+WInT/QC4xPWc5S4suEUmaIWSHpyJf5iQE2WEH3gM6VNIiXY0agAb1ePtG3nEs/+cAY4kvNDUsEsyEV7sXRpTWSV3ZO3GLPmb7V5A+cog1CRh0sBVCtgp/viA8WL+3s3sJ9UghWi3V5qKUeqLxGiNJHXTefHOvCGe73rhQXq1L8TwVuIRC8up0NeHAh6scmAfTSEKdSxI8buBTSnW1JSj4JF4yuz2+iqnFIe2IZs9sCuouXH1vTzK6G0UymL+ZQ66FetJwupyZRypEPxu+tcuq8amHErwGYncyq72nBxpYqOKNIdDICyRAtw== rares@getbetter.ro"

if $(grep -q "$THE_USER" /etc/shadow); then
  echo "Skipping $THE_USER user creation"
elif $(grep -q 'ubuntu' /etc/shadow); then
  echo "$THE_USER user does not exist, renaming ubuntu user..."
  mv /home/{ubuntu,$THE_USER}
  usermod -l $THE_USER -d /home/$THE_USER ubuntu
  groupmod -n $THE_USER ubuntu
  echo -n "$THE_USER:$THE_USER" | chpasswd

  echo "Renamed ubuntu user to $THE_USER and changed password."
else
  echo "Creating $THE_USER user..."

  useradd --create-home -s /bin/bash $THE_USER
  adduser $THE_USER sudo
  echo -n "$THE_USER:$THE_USER" | chpasswd
fi

# Configure SSH access
if [ -d /home/${THE_USER}/.ssh ]; then
  echo "Skipping $THE_USER SSH credentials configuration"
else
  echo 'SSH key has not been set'
  mkdir -p /home/${THE_USER}/.ssh
  echo $SSH_KEY > /home/${THE_USER}/.ssh/authorized_keys
  chown -R $THE_USER:$THE_USER /home/${THE_USER}/.ssh

  echo "SSH credentials configured for the $THE_USER user."
fi

# Enable passwordless sudo for the $THE_USER user
if [ -f /etc/sudoers.d/${THE_USER} ]; then
  echo 'Skipping sudoers file creation.'
else
  echo 'Sudoers file was not found'
  echo "$THE_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${THE_USER}
  chmod 0440 /etc/sudoers.d/${THE_USER}

  echo 'Sudoers file created.'
fi