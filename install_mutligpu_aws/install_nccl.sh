#!/bin/bash
# Step 4: Install NCCL 2.23.4 (Fixed PREFIX)
set -e
export DEBIAN_FRONTEND=noninteractive

# Log file
LOG_FILE=nccl_install.log
echo "Starting NCCL installation at $(date)" | tee -a $LOG_FILE

# Verify CUDA
echo "Checking CUDA installation..." | tee -a $LOG_FILE
if ! [ -f /usr/local/cuda-12.8/bin/nvcc ]; then
	    echo "Error: CUDA 12.8 not found at /usr/local/cuda-12.8" | tee -a $LOG_FILE
	        exit 1
fi
nvcc --version | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Install dependencies
echo "Installing dependencies..." | tee -a $LOG_FILE
sudo apt-get update -y | tee -a $LOG_FILE
sudo apt-get install -y git libfabric-dev build-essential g++ make | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Clean up previous NCCL attempts
echo "Cleaning up previous NCCL attempts..." | tee -a $LOG_FILE
sudo rm -rf nccl /opt/nccl
sudo rm -f /usr/local/lib/libnccl* /usr/local/include/nccl* /usr/local/lib/pkgconfig/nccl.pc
rm -f ~/.bashrc.bak
cp ~/.bashrc ~/.bashrc.bak
# Remove old LD_LIBRARY_PATH entry
sed -i '/\/opt\/nccl\/build\/lib/d' ~/.bashrc
echo "" | tee -a $LOG_FILE

# Create NCCL install directory
echo "Setting up /opt/nccl..." | tee -a $LOG_FILE
sudo mkdir -p /opt/nccl/build
sudo chmod -R 777 /opt/nccl
echo "" | tee -a $LOG_FILE

# Clone NCCL
echo "Cloning NCCL repository..." | tee -a $LOG_FILE
git clone https://github.com/NVIDIA/nccl.git -b v2.23.4-1 | tee -a $LOG_FILE
cd nccl
echo "" | tee -a $LOG_FILE

# Build NCCL
echo "Building NCCL..." | tee -a $LOG_FILE
make -j$(nproc) CUDA_HOME=/usr/local/cuda-12.8 PREFIX=/opt/nccl/build | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Install NCCL
echo "Installing NCCL..." | tee -a $LOG_FILE
sudo make install PREFIX=/opt/nccl/build | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Set environment variable
echo "Setting LD_LIBRARY_PATH..." | tee -a $LOG_FILE
echo 'export LD_LIBRARY_PATH=/opt/nccl/build/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
echo "" | tee -a $LOG_FILE

# Verify installation
echo "Verifying NCCL installation..." | tee -a $LOG_FILE
ls -l /opt/nccl/build/lib/libnccl.so | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "NCCL installation completed at $(date)" | tee -a $LOG_FILE
cd ..
