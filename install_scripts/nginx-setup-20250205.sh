#!/bin/bash

# Set non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Check for server name and non-interactive flag
SERVER_NAME="${1}"
NON_INTERACTIVE="${2}"

if [ -z "$SERVER_NAME" ]; then
    echo "Error: Server name is required"
    echo "Usage: $0 <server_name> [--non-interactive]"
    exit 1
fi

# Install Nginx with non-interactive flags
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Prepare the Nginx server block configuration
CONFIG="map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name ${SERVER_NAME};

    # Configuration for the main application
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        client_max_body_size 100M;
    }

    # Configuration for the /extract_embeddings endpoint
    location /training {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_read_timeout 3000s;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        client_max_body_size 100M;
    }
}"

# Remove existing symlink if it exists (suppressing errors)
sudo rm -f /etc/nginx/sites-enabled/myapp 2>/dev/null

# Write the configuration to the Nginx available sites
echo "$CONFIG" | sudo tee /etc/nginx/sites-available/myapp > /dev/null

# Enable the new site
sudo ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/

# Remove default nginx site if it exists
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null

# Test nginx configuration
sudo nginx -t || {
    echo "Nginx configuration test failed"
    exit 1
}

# Restart Nginx to apply changes
sudo systemctl restart nginx

echo "Nginx has been configured and restarted for domain: ${SERVER_NAME}"
