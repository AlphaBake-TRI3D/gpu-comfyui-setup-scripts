#!/bin/bash
# Step 2: Install NVIDIA Driver and Fabric Manager
set -e
export DEBIAN_FRONTEND=noninteractive

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y build-essential dkms libtirpc-dev

# Clean up any residual NVIDIA/CUDA packages
sudo apt-get purge -y 'nvidia-*' 'cuda-*' 'libnvidia-*'
sudo apt-get autoremove -y
sudo apt-get autoclean

# Add NVIDIA CUDA repository
wget -qO - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | sudo gpg --dearmor -o /usr/share/keyrings/cuda-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cuda-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda.list
sudo apt-get update -y

# Install NVIDIA driver 570 and Fabric Manager
sudo apt-get install -y nvidia-driver-570 nvidia-fabricmanager-570 nvidia-utils-570

# Enable and start Fabric Manager
sudo systemctl enable nvidia-fabricmanager
sudo systemctl start nvidia-fabricmanager

# Reboot to ensure kernel modules load
sudo reboot
