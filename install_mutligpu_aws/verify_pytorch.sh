#!/bin/bash
# Verification Script for Step 5: PyTorch
set -e

LOG_FILE=pytorch_verify.log
echo "Starting PyTorch verification at $(date)" | tee -a $LOG_FILE

# Activate virtual environment
echo "Activating virtual environment..." | tee -a $LOG_FILE
source ~/diffusers/venv/bin/activate
echo "Python: $(which python)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verify LD_LIBRARY_PATH
echo "=== LD_LIBRARY_PATH ===" | tee -a $LOG_FILE
echo $LD_LIBRARY_PATH | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verify PyTorch
echo "=== PyTorch Verification ===" | tee -a $LOG_FILE
python -c "import torch; print('PyTorch Version:', torch.__version__); print('CUDA Version:', torch.version.cuda); print('CUDA Available:', torch.cuda.is_available()); print('GPU Count:', torch.cuda.device_count()); print('GPU Names:', [torch.cuda.get_device_name(i) for i in range(torch.cuda.device_count())])" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verify ControlNet dependencies
echo "=== ControlNet Dependencies ===" | tee -a $LOG_FILE
python -c "import diffusers; print('Diffusers Version:', diffusers.__version__)" | tee -a $LOG_FILE
python -c "import transformers; print('Transformers Version:', transformers.__version__)" | tee -a $LOG_FILE
python -c "import accelerate; print('Accelerate Version:', accelerate.__version__)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verify NCCL integration with torchrun
echo "=== NCCL Integration ===" | tee -a $LOG_FILE
echo "Running NCCL test with torchrun..." | tee -a $LOG_FILE
cat > nccl_test.py << EOL
import torch
from torch import distributed as dist

dist.init_process_group(backend='nccl')
rank = dist.get_rank()
world_size = dist.get_world_size()
print(f'Rank {rank}/{world_size}: NCCL Initialized Successfully')
dist.destroy_process_group()
EOL
torchrun --nproc_per_node=8 nccl_test.py | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "PyTorch verification completed at $(date)" | tee -a $LOG_FILE
deactivate
