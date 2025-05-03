#!/bin/bash
# Verification Script for Steps 2 and 3
set -e

echo "=== NVIDIA Driver and GPU Status ==="
nvidia-smi
echo ""

echo "=== CUDA Toolkit Version ==="
nvcc --version
echo ""

echo "=== CUDA Runtime Version ==="
nvidia-smi -q | grep CUDA
echo ""

echo "=== Fabric Manager Status ==="
sudo systemctl status nvidia-fabricmanager | grep -E "Active|Connected|NVSwitches"
echo ""

echo "=== Kernel Modules ==="
lsmod | grep nvidia
modinfo nvidia | grep version
echo ""

echo "=== Environment Variables ==="
echo "PATH (cuda):"
echo $PATH | grep cuda
echo "LD_LIBRARY_PATH (cuda):"
echo $LD_LIBRARY_PATH | grep cuda
echo ""

echo "=== CUDA Symbolic Link ==="
ls -l /usr/local/cuda
echo ""
