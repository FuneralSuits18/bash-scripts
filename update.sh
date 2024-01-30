#!/bin/bash

# 1. Make it executable: 'chmod +x update.sh'
# 2. Move it to PATH: 'sudo mv update.sh /usr/local/bin/update'
# 3. Test: run 'sudo update' and see if it works

# Check if the user has sudo privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with sudo." 1>&2
    exit 1
fi

# Perform package updates
dnf update && flatpak update
