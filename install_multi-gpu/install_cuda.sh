#!/bin/bash
# Step 3: Install CUDA Toolkit 12.8
set -e
export DEBIAN_FRONTEND=noninteractive

# Update package lists
sudo apt-get update -y

# Install CUDA Toolkit 12.8
sudo apt-get install -y cuda-toolkit-12-8

# Set environment variables
echo 'export PATH=/usr/local/cuda-12.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Ensure CUDA symbolic link
sudo ln -sfn /usr/local/cuda-12.8 /usr/local/cuda
