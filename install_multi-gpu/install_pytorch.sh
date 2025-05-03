#!/bin/bash
# Step 5: Install PyTorch 2.5.0 and ControlNet Dependencies
set -e
export DEBIAN_FRONTEND=noninteractive

# Log file
LOG_FILE=pytorch_install.log
echo "Starting PyTorch installation at $(date)" | tee -a $LOG_FILE

# Clean up LD_LIBRARY_PATH duplicates in ~/.bashrc
echo "Cleaning up LD_LIBRARY_PATH in ~/.bashrc..." | tee -a $LOG_FILE
cp ~/.bashrc ~/.bashrc.bak
sed -i '/LD_LIBRARY_PATH/d' ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/nccl/build/lib:/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Install Python dependencies
echo "Installing Python dependencies..." | tee -a $LOG_FILE
sudo apt-get update -y | tee -a $LOG_FILE
sudo apt-get install -y python3 python3-pip python3-venv | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Create and activate virtual environment
echo "Creating virtual environment..." | tee -a $LOG_FILE
python3 -m venv controlnet_env
source controlnet_env/bin/activate
echo "Virtual environment activated: $(which python3)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Upgrade pip
echo "Upgrading pip..." | tee -a $LOG_FILE
pip install --upgrade pip | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Install PyTorch 2.5.0 with CUDA 12.8
echo "Installing PyTorch 2.5.0..." | tee -a $LOG_FILE
pip install torch==2.5.0 torchvision==0.20.0 torchaudio==2.5.0 --index-url https://download.pytorch.org/whl/cu128 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Install ControlNet dependencies
echo "Installing ControlNet dependencies..." | tee -a $LOG_FILE
pip install diffusers transformers accelerate | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verify PyTorch installation
echo "Verifying PyTorch installation..." | tee -a $LOG_FILE
python3 -c "import torch; print('PyTorch Version:', torch.__version__); print('CUDA Available:', torch.cuda.is_available()); print('GPU Count:', torch.cuda.device_count())" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "PyTorch installation completed at $(date)" | tee -a $LOG_FILE
