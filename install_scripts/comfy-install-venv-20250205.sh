#!/bin/bash

# Set non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

echo "Installing system dependencies..."
sudo apt-get update || handle_error "Failed to update package lists"
sudo apt-get install -y python3-pip python3.10-dev unzip || handle_error "Failed to install system dependencies"

echo "Installing virtualenv..."
python3 -m pip install --no-cache-dir virtualenv || handle_error "Failed to install virtualenv"

echo "Navigating to home directory..."
cd || handle_error "Failed to change to home directory"

echo "Cloning ComfyUI repository..."
# Add GitHub to known hosts if not already done
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

# Clone and setup ComfyUI
git clone git@github.com:comfyanonymous/ComfyUI.git || handle_error "Failed to clone ComfyUI"
cd ComfyUI || handle_error "Failed to enter ComfyUI directory"

echo "Setting up custom nodes..."
cd custom_nodes || handle_error "Failed to enter custom_nodes directory"
git reset --hard a57d635c5f36c28c59ea6513878acde80e4df180 || handle_error "Failed to reset ComfyUI version"

echo "Cloning additional custom nodes..."
git clone git@github.com:ltdrdata/ComfyUI-Manager.git || handle_error "Failed to clone ComfyUI-Manager"
git clone git@github.com:M1kep/ComfyLiterals.git || handle_error "Failed to clone ComfyLiterals"

echo "Setting up Python virtual environment..."
cd .. || handle_error "Failed to return to ComfyUI directory"
python3 -m virtualenv venv || handle_error "Failed to create virtual environment"
source venv/bin/activate || handle_error "Failed to activate virtual environment"

echo "Installing Python requirements..."
pip install --no-cache-dir -r requirements.txt || handle_error "Failed to install requirements"

echo "ComfyUI setup completed successfully!" 
