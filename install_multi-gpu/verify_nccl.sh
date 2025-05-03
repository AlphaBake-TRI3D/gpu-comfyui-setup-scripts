#!/bin/bash
# Verification Script for Step 4: NCCL
set -e

LOG_FILE=nccl_verify.log
echo "Starting NCCL verification at $(date)" | tee -a $LOG_FILE

echo "=== NCCL Installation ===" | tee -a $LOG_FILE
ls -l /opt/nccl/build/lib/libnccl.so | tee -a $LOG_FILE
ls -l /opt/nccl/build/lib/ | tee -a $LOG_FILE
ls -l /opt/nccl/build/include/ | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== NCCL Environment Variable ===" | tee -a $LOG_FILE
echo "LD_LIBRARY_PATH (nccl):" | tee -a $LOG_FILE
echo $LD_LIBRARY_PATH | grep nccl | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "=== NCCL Multi-GPU Test ===" | tee -a $LOG_FILE
echo "Cleaning up existing nccl-tests directory..." | tee -a $LOG_FILE
rm -rf nccl-tests
echo "Cloning nccl-tests..." | tee -a $LOG_FILE
git clone https://github.com/NVIDIA/nccl-tests.git | tee -a $LOG_FILE
cd nccl-tests
echo "Building nccl-tests..." | tee -a $LOG_FILE
make CUDA_HOME=/usr/local/cuda-12.8 NCCL_HOME=/opt/nccl/build | tee -a $LOG_FILE
echo "Running all_reduce_perf..." | tee -a $LOG_FILE
export NCCL_P2P_LEVEL=NVL
export NCCL_IB_DISABLE=1
export NCCL_ALGO=Ring
./build/all_reduce_perf -b 8 -e 4G -f 2 -g 8 | tee -a $LOG_FILE
cd ..
echo "" | tee -a $LOG_FILE

echo "NCCL verification completed at $(date)" | tee -a $LOG_FILE
