#!/bin/bash

# Check if domain argument is provided
if [ -z "$1" ]; then
    echo "Error: Domain name argument is required"
    echo "Usage: $0 <domain-name>"
    echo "Example: $0 loras7us2.tri3d.in"
    exit 1
fi


DOMAIN=$1
SETUP_DIR="/home/ubuntu/AlphaBake-Loras/setup-files/20250205-catflux-1.4.4.1"

echo "Starting full setup process..."
echo "Domain: $DOMAIN"

# Set DEBIAN_FRONTEND to noninteractive for all apt operations
export DEBIAN_FRONTEND=noninteractive

# Install NVIDIA drivers with non-interactive flags
echo "Step 1: Installing NVIDIA drivers..."
bash nvidia-setup-20250205.sh --silent

# Setup nginx with non-interactive mode
echo "Step 2: Setting up nginx..."
bash nginx-setup-20250205.sh "$DOMAIN" --non-interactive

# Setup Flask Training (includes Python dependencies)
echo "Step 3: Setting up Flask Training..."
bash flask-training-setup.sh --yes

# Setup ComfyUI
echo "Step 4: Installing ComfyUI..."
bash comfy-install-venv-20250205.sh --non-interactive

echo "Step 5: Installing ComfyUI nodes..."
bash comfy-nodes-install.sh --yes

# Download models
echo "Step 6: Downloading models..."
bash download-comfyui-models.sh --no-prompt

