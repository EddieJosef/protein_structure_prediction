#!/bin/bash

# Set installation path and license holder name
install_path=$(pwd)/scwrl4
license_holder="Eid Rashed"

# Ensure the installer is executable
chmod +x install_scwrl4.0.2_64bit_2020_linux

# Automate the installer inputs using echo
echo -e "${install_path}\ny\n${license_holder}" | ./install_scwrl4.0.2_64bit_2020_linux

# Verify installation
if command -v scwrl4/Scwrl4 >/dev/null; then
    echo "SCWRL4 installed successfully!"
else
    echo "SCWRL4 installation failed."
    exit 1
fi
