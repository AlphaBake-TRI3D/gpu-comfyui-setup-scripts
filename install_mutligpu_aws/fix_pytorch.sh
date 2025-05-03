#!/bin/bash
# Fix PyTorch and ControlNet Dependencies in Existing venv
set -e

# Log file
LOG_FILE=fix_pytorch.log
echo "Starting PyTorch fix at $(date)" | tee -a $LOG_FILE

# Activate virtual environment
echo "Activating virtual environment..." | tee -a $LOG_FILE
source ~/diffusers/venv/bin/activate
echo "Python: $(which python3)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Uninstall existing PyTorch
echo "Uninstalling existing PyTorch..." | tee -a $LOG_FILE
pip uninstall -y torch torchvision torchaudio | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Install PyTorch 2.5.0 with CUDA 12.8
echo "Installing PyTorch 2.5.0..." | tee -a $LOG_FILE
pip install torch==2.5.0 torchvision==0.20.0 torchaudio==2.5.0 --index-url https://download.pytorch.org/whl/cu128 | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Reinstall ControlNet dependencies
echo "Reinstalling ControlNet dependencies..." | tee -a $LOG_FILE
pip install diffusers transformers accelerate --force-reinstall | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verify PyTorch installation
echo "Verifying PyTorch installation..." | tee -a $LOG_FILE
python3 -c "import torch; print('PyTorch Version:', torch.__version__); print('CUDA Version:', torch.version.cuda); print('CUDA Available:', torch.cuda.is_available()); print('GPU Count:', torch.cuda.device_count()); print('GPU Names:', [torch.cuda.get_device_name(i) for i in range(torch.cuda.device_count())])" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "PyTorch fix completed at $(date)" | tee -a $LOG_FILE
deactivate
