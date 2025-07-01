#!/usr/bin/env bash

# WikiJS Integration Container Deployment
# One-line deployment: bash -c "$(wget -qLO - https://raw.githubusercontent.com/homelab-gitops-auditor/community-scripts/main/ct/wikijs-integration.sh)"

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

set -euo pipefail
shopt -s inherit_errexit nullglob

# Default values
CT_TYPE="1"
PW=""
CT_ID=""
CT_NAME="wikijs-integration"
CT_HOSTNAME="wikijs-integration"
DISK_SIZE="4"
CORE_COUNT="2"
RAM_SIZE="1024"
BRG="vmbr0"
NET="dhcp"
GATE=""
APT_CACHER=""
APT_CACHER_IP=""
DISABLEIP6="no"
MTU=""
SD=""
NS=""
MAC=""
VLAN=""
SSH="no"
VERB="no"
FUSE="no"
UPDATE_MODE="no"

# Functions
header_info() {
    clear
    cat <<"EOF"
 _       _ _ _   _ _____   ___       _                       _   _
| |     (_) | | | |_   _| |_ _|_ __ | |_ ___  __ _ _ __ __ _| |_(_) ___  _ __
| | /\  | | | |/ /  | |    | || '_ \| __/ _ \/ _` | '__/ _` | __| |/ _ \| '_ \
| |/  \ | |   <   | |    | || | | | ||  __/ (_| | | | (_| | |_| | (_) | | | |
|__/\__\|_|_|\_\  |_|   |___|_| |_|\__\___|\__, |_|  \__,_|\__|_|\___/|_| |_|
                                          |___/

EOF
}

msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
    local msg="$1"
    echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

start_routine() {
    if command -v pveversion >/dev/null 2>&1; then
        if ! pveversion | grep -Eq "pve-manager/(8\.[0-9])"; then
            msg_error "This version of Proxmox Virtual Environment is not supported"
            echo -en "\n Please use Proxmox VE 8.0 or later"
            exit 1
        fi
    else
        msg_error "No PVE Detected"
        exit 1
    fi
}

check_existing_container() {
    # Check for existing WikiJS Integration containers
    local existing_containers=$(pct list | grep -E "(wikijs-integration|WikiJS.*Integration)" | awk '{print $1}')
    
    if [[ -n "$existing_containers" ]]; then
        echo -e "${YW}Found existing WikiJS Integration container(s):${CL}"
        for container_id in $existing_containers; do
            local container_name=$(pct config $container_id | grep "hostname:" | cut -d' ' -f2)
            local container_status=$(pct status $container_id | cut -d' ' -f2)
            echo -e "  ${BL}ID: $container_id${CL} | ${BL}Name: $container_name${CL} | ${BL}Status: $container_status${CL}"
        done
        
        echo -e "\n${YW}Would you like to:${CL}"
        echo -e "  ${GN}1)${CL} Update existing container"
        echo -e "  ${GN}2)${CL} Create new container"
        echo -e "  ${RD}3)${CL} Exit"
        
        while true; do
            read -p "Please choose an option (1-3): " choice
            case $choice in
                1)
                    UPDATE_MODE="yes"
                    CT_ID=$(echo $existing_containers | head -n1)
                    msg_info "Selected container $CT_ID for update"
                    msg_ok "Update mode enabled"
                    break
                    ;;
                2)
                    UPDATE_MODE="no"
                    msg_info "Creating new container"
                    msg_ok "Create mode enabled"
                    break
                    ;;
                3)
                    echo -e "${RD}Exiting...${CL}"
                    exit 0
                    ;;
                *)
                    echo -e "${RD}Invalid option. Please choose 1, 2, or 3.${CL}"
                    ;;
            esac
        done
    else
        UPDATE_MODE="no"
        msg_info "No existing WikiJS Integration containers found"
        msg_ok "Will create new container"
    fi
}

find_available_id() {
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        return # CT_ID already set
    fi
    
    # Find next available container ID starting from 130
    for i in {130..200}; do
        if ! pct status $i &>/dev/null; then
            CT_ID="$i"
            break
        fi
    done
    
    if [[ -z "$CT_ID" ]]; then
        msg_error "No available container IDs found in range 130-200"
        exit 1
    fi
}

default_settings() {
    CTID="$CT_ID"
    CTNAME="$CT_NAME"
    HOSTNAME="$CT_HOSTNAME"
    
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        # Get existing container configuration
        local existing_config=$(pct config $CTID)
        HOSTNAME=$(echo "$existing_config" | grep "hostname:" | cut -d' ' -f2)
        
        echo -e "${DGN}Update Mode - Using Existing Container:${CL}"
        echo -e "${DGN}Container ID: ${BL}$CTID${CL}"
        echo -e "${DGN}Current Hostname: ${BL}$HOSTNAME${CL}"
        echo -e "${DGN}Mode: ${YW}UPDATE${CL}"
    else
        # New container settings
        DISK_SIZE="$DISK_SIZE"
        CORE_COUNT="$CORE_COUNT"
        RAM_SIZE="$RAM_SIZE"
        BRG="$BRG"
        NET="192.168.1.200/24"
        GATE="192.168.1.1"
        MTU=""
        SD=""
        NS="192.168.1.1"
        MAC=""
        VLAN=""
        SSH="$SSH"
        VERB="$VERB"
        FUSE="$FUSE"
        
        echo -e "${DGN}Create Mode - New Container Settings:${CL}"
        echo -e "${DGN}Container ID: ${BL}$CTID${CL}"
        echo -e "${DGN}Container Name: ${BL}$CTNAME${CL}"
        echo -e "${DGN}Hostname: ${BL}$HOSTNAME${CL}"
        echo -e "${DGN}Disk Size: ${BL}$DISK_SIZE GB${CL}"
        echo -e "${DGN}CPU Cores: ${BL}$CORE_COUNT${CL}"
        echo -e "${DGN}RAM: ${BL}$RAM_SIZE MB${CL}"
        echo -e "${DGN}Bridge: ${BL}$BRG${CL}"
        echo -e "${DGN}Static IP: ${BL}$NET${CL}"
        echo -e "${DGN}Gateway: ${BL}$GATE${CL}"
        echo -e "${DGN}DNS: ${BL}$NS${CL}"
        echo -e "${DGN}Mode: ${GN}CREATE${CL}"
    fi
}

build_container() {
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        msg_info "Preparing existing container for update"
        
        # Ensure container is stopped
        if pct status $CTID | grep -q "running"; then
            msg_info "Stopping container $CTID"
            pct stop $CTID >/dev/null 2>&1
            msg_ok "Stopped container"
        fi
        
        # Update container tags to include wikijs integration
        pct set $CTID --tags "gitops;integration;nodejs;wikijs;production" >/dev/null 2>&1
        
        msg_ok "Prepared existing container for update"
    else
        msg_info "Creating new LXC container"
        
        # Get latest Debian template
        TEMPLATE="debian-12-standard_12.7-1_amd64.tar.zst"
        if ! pveam list local | grep -q "$TEMPLATE"; then
            msg_info "Downloading $TEMPLATE"
            pveam download local $TEMPLATE >/dev/null 2>&1
            msg_ok "Downloaded $TEMPLATE"
        fi
        
        # Container configuration
        TEMP_DIR=$(mktemp -d)
        cat > $TEMP_DIR/container.conf << EOF
arch: amd64
cores: $CORE_COUNT
hostname: $HOSTNAME
memory: $RAM_SIZE
net0: name=eth0,bridge=$BRG,hwaddr=auto,ip=$NET,gw=$GATE,type=veth
ostype: debian
rootfs: local-lvm:$DISK_SIZE
swap: 512
tags: gitops;integration;nodejs;wikijs;production
unprivileged: 1
EOF
        
        # Create container
        pvesh create /nodes/$(hostname)/lxc -vmid $CTID -ostemplate local:vztmpl/$TEMPLATE -file $TEMP_DIR/container.conf >/dev/null 2>&1
        
        # Configure DNS
        lxc-attach -n $CTID -- bash -c "echo 'nameserver $NS' > /etc/resolv.conf"
        
        rm -rf $TEMP_DIR
        msg_ok "Created new LXC container"
    fi
}

install_script() {
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        msg_info "Starting container and updating WikiJS Integration"
    else
        msg_info "Starting container and installing WikiJS Integration"
    fi
    
    # Start container
    pct start $CTID >/dev/null 2>&1
    
    # Wait for container to be ready
    sleep 10
    
    # Check if this is an update and if WikiJS Integration is already installed
    EXISTING_INSTALL="no"
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        if pct exec $CTID -- test -d /opt/wikijs-integration; then
            EXISTING_INSTALL="yes"
            msg_info "Found existing WikiJS Integration installation"
            
            # Get current version
            local current_version=""
            if pct exec $CTID -- test -f /opt/wikijs-integration/package.json; then
                current_version=$(pct exec $CTID -- grep '"version"' /opt/wikijs-integration/package.json | cut -d'"' -f4)
            fi
            
            msg_ok "Current version: ${current_version:-unknown}"
        fi
    fi
    
    # Transfer and execute installation script
    cat > /tmp/wikijs-integration-install.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Update system
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y curl sudo mc git sqlite3 nginx

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install PM2
npm install -g pm2

# Create wikijs-integration user
useradd -r -s /bin/bash -d /opt/wikijs-integration wikijs-integration
mkdir -p /opt/wikijs-integration
chown -R wikijs-integration:wikijs-integration /opt/wikijs-integration

# Clone repository (using the current development code as template)
cd /opt/wikijs-integration
sudo -u wikijs-integration git init
sudo -u wikijs-integration git remote add origin https://github.com/homelab-gitops-auditor/homelab-gitops-auditor.git || true

# For now, create a minimal package.json
sudo -u wikijs-integration cat > package.json << 'PKGJSON'
{
  "name": "wikijs-integration",
  "version": "1.0.0",
  "description": "WikiJS Integration Service for GitOps Auditor",
  "main": "api/server-mcp.js",
  "scripts": {
    "start": "node api/server-mcp.js",
    "prod": "NODE_ENV=production node api/server-mcp.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "sqlite3": "^5.1.6",
    "cors": "^2.8.5",
    "express-ws": "^5.0.2",
    "chokidar": "^3.5.3",
    "node-fetch": "^2.7.0"
  },
  "keywords": ["wikijs", "gitops", "integration"],
  "author": "homelab-gitops-auditor",
  "license": "MIT"
}
PKGJSON

# Install Node.js dependencies
sudo -u wikijs-integration npm install

# Create basic API directory structure
sudo -u wikijs-integration mkdir -p api

# Create a basic server file (will be replaced by real deployment)
sudo -u wikijs-integration cat > api/server-mcp.js << 'SERVERJS'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'wikijs-integration', timestamp: new Date().toISOString() });
});

app.get('/wiki-agent/status', (req, res) => {
  res.json({ 
    status: 'running', 
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`WikiJS Integration Service running on port ${PORT}`);
});
SERVERJS

# Create production environment file
cat > /opt/wikijs-integration/production.env << 'ENVFILE'
NODE_ENV=production
PORT=3001
WIKIJS_URL=http://192.168.1.90:3000
WIKIJS_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGkiOjIsImdycCI6MSwiaWF0IjoxNzUwNjg5NzQ0LCJleHAiOjE3NTMyODE3NDQsImF1ZCI6InVybjp3aWtpLmpzIiwiaXNzIjoidXJuOndpa2kuanMifQ.rcGzUI_zmRmFhin90HM2BuB6n4CcCUYY2kHBL7aYg2C114U1GkAD_UHIEmo-6lH-qFESgh34MBTs_6-WUCxDQIg-Y2rPeKZqY8nnFrwrrFwXu6s3cyomHw4QclHWa1_OKs0BCausZWYWkgLagELx3WNw42Zs8YqH0yfjYqNQFy-Vh1jAphtoloFtKRZ0DIWSYE-oxwDywu3Qkh5XFIf0hZKOAu3XKD8da0G3WFpw4JB9v7ubHYNHJBdzp8RpLov-f6Xh5AYGuel1N4PCIbVRegpCKUVbHwZgYHrkTWwae-8D_9tphg1zAbGoQQ2bU-IPsFfcyFg8RDYViJiH2qaL0g
DEBUG_WIKI_AGENT=true
ENVFILE

chown wikijs-integration:wikijs-integration /opt/wikijs-integration/production.env
chmod 600 /opt/wikijs-integration/production.env

# Create PM2 ecosystem file
sudo -u wikijs-integration cat > /opt/wikijs-integration/ecosystem.config.js << 'ECOSYSTEM'
module.exports = {
  apps: [{
    name: 'wikijs-integration',
    script: './api/server-mcp.js',
    cwd: '/opt/wikijs-integration',
    user: 'wikijs-integration',
    env_file: '/opt/wikijs-integration/production.env',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '512M',
    error_file: '/var/log/wikijs-integration/error.log',
    out_file: '/var/log/wikijs-integration/out.log',
    log_file: '/var/log/wikijs-integration/combined.log',
    time: true,
    restart_delay: 5000,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
ECOSYSTEM

# Create log directory
mkdir -p /var/log/wikijs-integration
chown wikijs-integration:wikijs-integration /var/log/wikijs-integration

# Start service with PM2
sudo -u wikijs-integration pm2 start /opt/wikijs-integration/ecosystem.config.js
sudo -u wikijs-integration pm2 save

# Create systemd service
cat > /etc/systemd/system/wikijs-integration.service << 'SYSTEMD'
[Unit]
Description=WikiJS Integration Service
After=network.target

[Service]
Type=forking
User=wikijs-integration
WorkingDirectory=/opt/wikijs-integration
ExecStart=/usr/bin/pm2 start ecosystem.config.js --no-daemon
ExecReload=/usr/bin/pm2 reload ecosystem.config.js
ExecStop=/usr/bin/pm2 stop ecosystem.config.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable wikijs-integration

# Configure nginx reverse proxy
cat > /etc/nginx/sites-available/wikijs-integration << 'NGINX'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/wikijs-integration /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl enable nginx
systemctl restart nginx

# Initialize SQLite database
sudo -u wikijs-integration sqlite3 /opt/wikijs-integration/wiki-agent.db "PRAGMA user_version = 1;"

# Clean up
apt-get autoremove -y
apt-get autoclean
EOF

    # Execute installation script in container
    pct exec $CTID -- bash < /tmp/wikijs-integration-install.sh
    
    # Clean up
    rm /tmp/wikijs-integration-install.sh
    
    msg_ok "Installed WikiJS Integration"
}

# Main execution
header_info
start_routine
check_existing_container
find_available_id
default_settings
build_container
install_script

# Final status
IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
msg_ok "Completed Successfully!"
echo -e "${DGN}WikiJS Integration Service${CL} should be reachable at: ${BL}http://$IP${CL}"
echo -e "${DGN}Health check: ${BL}http://$IP/health${CL}"
echo -e "${DGN}Service status: ${BL}http://$IP/wiki-agent/status${CL}"