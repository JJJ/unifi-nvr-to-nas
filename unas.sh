#!/usr/bin/env bash

#
# 0. Start
#
echo
echo "Starting..."

#
# 1. Protect
#
echo
echo "Step 1. Protect"

# Stop it
echo "-- Stopping..."
systemctl stop unifi-protect
echo "---- OK!"

# Disable autostart on boot/reboot
echo "-- Disabling..."
systemctl -q disable unifi-protect >/dev/null 2>/dev/null
echo "---- OK!"

#
# 2. Samba
#
echo
echo "Step 2. Install Samba"

# Install Samba
echo "-- Installing..."
apt-get install samba >/dev/null 2>/dev/null
echo "---- OK!"

# Start the samba service
echo "-- Starting..."
service smbd start
echo "---- OK!"

# Set the service to start on boot/reboot
echo "-- Autoloading..."
systemctl -q enable smbd.service >/dev/null 2>/dev/null
echo "---- OK!"

#
# 3. Config
#
echo
echo "Step 3. Config"

# Make a backup copy of the smb.conf file
echo "-- Creating backup of Samba config..."
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
echo "---- OK!"

# Add this to smb.conf
echo "-- Creating new Samba config..."
cat > /etc/samba/smb.conf <<EOF
#============================ Global definition ================================

[global]
  workgroup = WORKGROUP
  server string = Samba Server %v
  log file = /var/log/samba/%m.log
  max log size = 50
  security = user
  map to guest = never
  dns proxy = no

#============================ Share Definitions ==============================

[Public]
  path = /volume1/Samba/Public
  public = yes
  guest only = yes
  browseable = yes
  writable = yes
  force create mode = 0666
  force directory mode = 0777

[Protected]
  path = /volume1/Samba/Protected
  valid users = @unasmbgrp
  browsable = yes
  writable = yes
  read only = no
EOF

echo "---- OK!"

#
# 4. Add User & Usergroup
#
echo
echo "Step 4. Auth"

# Create a user
echo "-- Adding user..."
adduser -q unasamba >/dev/null 2>/dev/null
echo "---- OK!"

# Create a user group
echo "-- Adding usergroup..."
addgroup -q unasmbgrp >/dev/null 2>/dev/null
echo "---- OK!"

# Add user to group
echo "-- Adding user to usergroup..."
adduser -q unasamba unasmbgrp >/dev/null 2>/dev/null
echo "---- OK!"

# Create a Samba password
echo "-- Adding user password..."
echo -e "unasamba\nunasamba" | smbpasswd -a -s unasamba
echo "---- OK!"

#
# 5. Add Directories
#
echo
echo "Step 5. Directories"

# Make directories for Public and Protected
echo "-- Creating directories..."
[ -d /volume1/Samba ] || mkdir /volume1/Samba
[ -d /volume1/Samba/Public ] || mkdir /volume1/Samba/Public
[ -d /volume1/Samba/Protected ] || mkdir /volume1/Samba/Protected
echo "---- OK!"

# Set the permissions on the new directories
echo "-- Setting permissions..."
chmod -R ugo+w /volume1/Samba/Public
chmod -R 0770 /volume1/Samba/Protected
chown root:unasmbgrp /volume1/Samba/Protected
echo "---- OK!"

# Restart Samba so changes take effect
echo "-- Restarting Samba..."
service smbd restart
echo "---- OK!"

# Output protected auth
echo
echo "-- Access a Protected directory:"
echo "---- U: unasamba"
echo "---- P: unasamba"

# Done
echo
echo "All done!"
echo
