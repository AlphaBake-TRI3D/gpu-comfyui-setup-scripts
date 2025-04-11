#!/usr/bin/sh

# Set non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Remove any existing NVIDIA installations
sudo apt-get purge -y 'nvidia-*' 'cuda-*' 'libnvidia-*'
sudo apt-get autoremove -y
sudo apt-get autoclean

# Add NVIDIA repository and keys (Use the latest method)
wget -qO - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | sudo gpg --dearmor -o /usr/share/keyrings/cuda-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cuda-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda.list

# Update package lists
sudo apt-get update -y

# Install packages without prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ubuntu-drivers-common python3-pip

# Auto-detect and install the recommended NVIDIA driver without prompts
sudo DEBIAN_FRONTEND=noninteractive ubuntu-drivers autoinstall

# Install the latest NVIDIA drivers and utilities without prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" nvidia-driver nvidia-utils

# Install the latest CUDA without prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" cuda

# Check installation
nvidia-smi || echo "nvidia-smi failed - reboot required"

# Reboot immediately
echo "Installation complete. System will reboot now."
# sudo reboot

