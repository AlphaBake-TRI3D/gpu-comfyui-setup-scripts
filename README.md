# Setup A100X8 GPU machines on Ubuntu 22.04 
Follow the script in install-multi-gpu


# GPU ComfyUI Setup Scripts

This repository contains setup scripts for deploying ComfyUI with GPU support on cloud virtual machines.

## Prerequisites

- A cloud VM with Ubuntu (tested on Ubuntu 20.04/22.04)
- Root access to the VM
- DNS management access to configure domain routing
- Base directory: `/home/ubuntu`

## Quick Start

1. Clone this repository:
```bash
cd /home/ubuntu
git clone <repository-url> gpu-comfyui-setup-scripts
```

2. Configure environment variables:
```bash
cd gpu-comfyui-setup-scripts/install_scripts
cp .env_sample .env
# Edit .env file with your credentials for model downloads
```

3. Run the setup script:
```bash
bash full-setup.sh your-domain.com
```
Note: Make sure to configure your DNS to point your domain to your VM's IP address.

## Running ComfyUI

1. Navigate to ComfyUI directory and activate virtual environment:
```bash
cd ~/ComfyUI
source venv/bin/activate
```

2. Start the server:
```bash
python main.py --port 3000
```
The server will be accessible on port 80 through nginx reverse proxy.

## Customization

You can customize your ComfyUI installation by modifying:
- `repos.txt`: Add or remove additional repositories
- `download-comfyui-models.sh`: Configure which models to download

## Configuration

- Default ComfyUI port: 3000
- Nginx forwards port 80 to 3000
- Installation path: `/home/ubuntu/ComfyUI`

## Notes

- The setup assumes a fresh Ubuntu installation
- All scripts should be run as the ubuntu user with sudo privileges
- Make sure to properly secure your environment variables and credentials
- Check start_server.py and stop_server.py in start_stop_machines folder 

## Support

For issues and support, please open an issue in the repository.
