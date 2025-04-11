#!/bin/bash

# Set non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Error handling function
handle_error() {
    echo "Error: $1"
    exit 1
}

# Read HF token from config file
if [ ! -f /home/ubuntu/AlphaBake-Loras/flask-training/.env ]; then
    handle_error "/home/ubuntu/AlphaBake-Loras/flask-training/.env file not found"
fi

# Source the API keys
source .env

# Check if HF token is available
if [ -z "$HF_TOKEN" ]; then
    handle_error "HF_TOKEN not found in /home/ubuntu/AlphaBake-Loras/flask-training/.env"
fi

# Check AWS credentials
if [ -z "$AWSAccessKeyId" ] || [ -z "$AWSSecretKey" ] || [ -z "$AWSRegion" ]; then
    handle_error "AWS credentials not found in /home/ubuntu/AlphaBake-Loras/flask-training/.env"
fi

# Install required packages non-interactively
echo "Installing required packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y || handle_error "Failed to update package lists"

# Check if aria2c is installed, if not install it
if ! command -v aria2c &> /dev/null; then
    echo "Installing aria2c..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y aria2 || handle_error "Failed to install aria2"
fi

# Install AWS CLI if needed
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y awscli || handle_error "Failed to install AWS CLI"
fi

# Setup AWS credentials
mkdir -p ~/.aws || handle_error "Failed to create AWS config directory"

# Write AWS credentials securely
cat > ~/.aws/credentials << EOF || handle_error "Failed to write AWS credentials"
[default]
aws_access_key_id = ${AWSAccessKeyId}
aws_secret_access_key = ${AWSSecretKey}
EOF

cat > ~/.aws/config << EOF || handle_error "Failed to write AWS config"
[default]
region = ${AWSRegion}
output = json
EOF

# Verify AWS credentials file was written correctly
if ! grep -q "${AWSAccessKeyId}" ~/.aws/credentials || ! grep -q "${AWSSecretKey}" ~/.aws/credentials; then
    handle_error "AWS credentials were not written correctly"
fi

# Simple aria2c download function with retries
# Parameters: $1=URL, $2=destination path
adown() {
    local url="$1"
    local dest="$2"
    local max_retries=3
    local retry_count=0
    
    # Skip if file already exists and is not empty
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "File already exists and is not empty, skipping: $dest"
        return 0
    fi
    
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")" || handle_error "Failed to create directory for: $dest"
    
    # Download with retries
    while [ $retry_count -lt $max_retries ]; do
        if aria2c \
            --max-connection-per-server=16 \
            --split=16 \
            --continue=true \
            --connect-timeout=60 \
            --timeout=600 \
            --dir="$(dirname "$dest")" \
            --out="$(basename "$dest")" \
            "$url"; then
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "Download failed, retrying in 5 seconds... (Attempt $retry_count of $max_retries)"
            sleep 5
        fi
    done
    
    handle_error "Failed to download after $max_retries attempts: $url"
}

# Function to handle zip downloads and extraction
handle_zip() {
    local zip_path="$1"
    local extract_dir="$2"
    
    # Create extraction directory
    mkdir -p "$extract_dir" || handle_error "Failed to create extraction directory: $extract_dir"
    
    # Extract and remove zip if successful
    if unzip -o "$zip_path" -d "$extract_dir"; then
        rm -f "$zip_path"
        echo "Successfully extracted and removed: $zip_path"
    else
        handle_error "Failed to extract: $zip_path"
    fi
}

# Function for Hugging Face downloads with auth
hf_download() {
    local url="$1"
    local dest="$2"
    local max_retries=3
    local retry_count=0
    
    # Skip if file already exists and is not empty
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "File already exists and is not empty, skipping: $dest"
        return 0
    fi
    
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")" || handle_error "Failed to create directory for: $dest"
    
    # Download with retries
    while [ $retry_count -lt $max_retries ]; do
        if aria2c \
            --max-connection-per-server=16 \
            --split=16 \
            --continue=true \
            --connect-timeout=60 \
            --timeout=600 \
            --header="Authorization: Bearer ${HF_TOKEN}" \
            --dir="$(dirname "$dest")" \
            --out="$(basename "$dest")" \
            "$url"; then
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "Download failed, retrying in 5 seconds... (Attempt $retry_count of $max_retries)"
            sleep 5
        fi
    done
    
    handle_error "Failed to download after $max_retries attempts: $url"
}

# Function for AWS S3 downloads with retries
s3_download() {
    local s3_path="$1"
    local dest="$2"
    local max_retries=3
    local retry_count=0
    
    # Skip if file already exists and is not empty
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "File already exists and is not empty, skipping: $dest"
        return 0
    fi

    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")" || handle_error "Failed to create directory for: $dest"
    
    # Download with retries
    while [ $retry_count -lt $max_retries ]; do
        echo "Downloading from S3 (Attempt $((retry_count + 1)) of $max_retries)..."
        if aws s3 cp "s3://alpha-bake-loras/${s3_path}" "${dest}"; then
            echo "Download completed successfully to: ${dest}"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "Download failed, retrying in 5 seconds..."
            sleep 5
            rm -f "${dest}" # Clean up partial download
        fi
    done
    
    rm -f "${dest}" # Clean up failed download
    handle_error "Failed to download after $max_retries attempts: s3://alpha-bake-loras/${s3_path}"
}

# Create required directories
for dir in clip vae unet loras style_models onnx "onnx/human-parts"; do
    mkdir -p "${HOME}/ComfyUI/models/${dir}" || handle_error "Failed to create directory: ${dir}"
done


cd "${HOME}/ComfyUI/models/clip_vision" || handle_error "Failed to change to clip_vision directory"
adown \
    'https://huggingface.co/google/siglip-so400m-patch14-384/resolve/main/model.safetensors' \
    "${HOME}/ComfyUI/models/clip_vision/sigclip_vision_path14_384.safetensors"

adown \
    'https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors' \
    "${HOME}/ComfyUI/models/vae/ae.safetensors"

adown \
    'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors' \
    "${HOME}/ComfyUI/models/clip/clip_l.safetensors"

adown \
    'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors' \
    "${HOME}/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors"


