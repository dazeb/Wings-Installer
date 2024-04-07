#!/bin/bash

# Install dependencies
apt update
apt install -y curl docker.io

# Start Docker on boot
systemctl enable --now docker

# Enable swap (optional)
echo 'GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"' >> /etc/default/grub
update-grub
