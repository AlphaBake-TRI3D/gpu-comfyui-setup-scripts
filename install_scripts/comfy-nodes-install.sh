#!/bin/bash

# Set non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Error handling function
handle_error() {
    echo "Error: $1"
    exit 1
}

CURRENT_DIR="/home/ubuntu/gpu-comfyui-setup-scripts/install_scripts/"
cd || handle_error "Failed to change to home directory"

CLONE_DIR="/home/ubuntu/ComfyUI/custom_nodes/"
source /home/ubuntu/ComfyUI/venv/bin/activate || handle_error "Failed to activate virtual environment"

# Ensure git doesn't prompt for credentials
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes"

# Ensure the clone directory exists
mkdir -p "$CLONE_DIR" || handle_error "Failed to create clone directory"

# Read each entry from the file
while IFS=',' read -r repo_url commit_id || [[ -n "$repo_url" ]]; do
    # Skip empty lines
    [ -z "$repo_url" ] && continue
    
    cd "$CLONE_DIR" || handle_error "Failed to change to clone directory"
    
    # Extract the repository name from the URL
    repo_name=$(echo "$repo_url" | awk -F '/' '{print $NF}' | sed 's/.git$//')
    
    echo "Processing repository: $repo_name"
    
    # Remove existing directory if present
    if [ -d "$repo_name" ]; then
        rm -rf "$repo_name" || handle_error "Failed to remove existing $repo_name"
    fi
    
    # Clone the repository
    echo "Cloning $repo_name into $CLONE_DIR..."
    if ! git clone "$repo_url" 2>/dev/null; then
        echo "Warning: Failed to clone $repo_name, skipping..."
        continue
    fi
    
    cd "$repo_name" || handle_error "Failed to enter $repo_name directory"
    
    # Reset to specific commit if provided
    if [ -n "$commit_id" ]; then
        if ! git reset --hard "$commit_id" 2>/dev/null; then
            echo "Warning: Failed to reset to commit $commit_id in $repo_name"
        fi
    fi
    
    # Install Python requirements if present
    if [ -f "requirements.txt" ]; then
        echo "Installing requirements for $repo_name..."
        if ! pip install --no-cache-dir --no-input -r requirements.txt; then
            echo "Warning: Failed to install requirements for $repo_name"
        fi
    fi
    
    # Run install script if present
    if [ -f "install.py" ]; then
        echo "Running install.py in $repo_name..."
        if ! python install.py; then
            echo "Warning: Failed to run install.py in $repo_name"
        fi
    fi
    
done < "$CURRENT_DIR/repos.txt"

echo "All repositories processed."
exit 0