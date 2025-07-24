#!/usr/bin/env bash

# NetBox Agent Container Deployment
# One-line deployment: bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"

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
CT_NAME="netbox-agent"
CT_HOSTNAME="netbox-agent"
DISK_SIZE="8"
CORE_COUNT="2"
RAM_SIZE="2048"
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
 _   _      _   ____               _                    _   
| \ | | ___| |_| __ )  _____  __  / \   __ _  ___ _ __ | |_ 
|  \| |/ _ \ __|  _ \ / _ \ \/ / / _ \ / _` |/ _ \ '_ \| __|
| |\  |  __/ |_| |_) | (_) >  < / ___ \ (_| |  __/ | | | |_ 
|_| \_|\___|\__|____/ \___/_/\_\_/   \_\__, |\___|_| |_|\__|
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
    # Check for existing NetBox Agent containers
    local existing_containers=$(pct list | grep -E "(netbox-agent|NetBox.*Agent)" | awk '{print $1}')
    
    if [[ -n "$existing_containers" ]]; then
        echo -e "${YW}Found existing NetBox Agent container(s):${CL}"
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
        msg_info "No existing NetBox Agent containers found"
        msg_ok "Will create new container"
    fi
}

find_available_id() {
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        return # CT_ID already set
    fi
    
    # Find next available container ID starting from 140
    for i in {140..200}; do
        if ! pct status $i &>/dev/null; then
            CT_ID="$i"
            break
        fi
    done
    
    if [[ -z "$CT_ID" ]]; then
        msg_error "No available container IDs found in range 140-200"
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
        NET="dhcp"
        GATE=""
        MTU=""
        SD=""
        NS=""
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
        echo -e "${DGN}Network: ${BL}$NET${CL}"
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
        
        # Update container tags to include netbox agent
        pct set $CTID --tags "netbox;agent;python;automation;infrastructure" >/dev/null 2>&1
        
        msg_ok "Prepared existing container for update"
    else
        msg_info "Creating new LXC container"
        
        # Get latest Debian template
        TEMPLATE="debian-12-standard_12.7-1_amd64.tar.zst"
        if ! pveam list local | grep -q "$TEMPLATE"; then
            msg_info "Downloading $TEMPLATE"
            if pveam download local $TEMPLATE; then
                msg_ok "Downloaded $TEMPLATE"
            else
                msg_error "Failed to download template $TEMPLATE"
                echo -e "${RD}Template download failed. Please check:${CL}"
                echo -e "- Internet connectivity"
                echo -e "- Available storage space"
                echo -e "- Proxmox template repository access"
                exit 1
            fi
        fi
        
        # Create container
        if pct create $CTID local:vztmpl/$TEMPLATE \
            --arch amd64 \
            --cores $CORE_COUNT \
            --hostname $HOSTNAME \
            --memory $RAM_SIZE \
            --net0 name=eth0,bridge=$BRG,ip=$NET,type=veth \
            --ostype debian \
            --rootfs local-lvm:$DISK_SIZE \
            --swap 1024 \
            --tags "netbox;agent;python;automation;infrastructure" \
            --unprivileged 1; then
            msg_ok "Created new LXC container"
        else
            msg_error "Failed to create LXC container"
            echo -e "${RD}Container creation failed. Please check:${CL}"
            echo -e "- Available storage space"
            echo -e "- Template availability: $TEMPLATE"
            echo -e "- Container ID $CTID not already in use"
            echo -e "- Network bridge $BRG exists"
            exit 1
        fi
    fi
}

install_script() {
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        msg_info "Starting container and updating NetBox Agent"
    else
        msg_info "Starting container and installing NetBox Agent"
    fi
    
    # Start container
    pct start $CTID >/dev/null 2>&1
    
    # Wait for container to be ready
    sleep 10
    
    # Check if this is an update and if NetBox Agent is already installed
    EXISTING_INSTALL="no"
    if [[ "$UPDATE_MODE" == "yes" ]]; then
        if pct exec $CTID -- test -d /opt/netbox-agent; then
            EXISTING_INSTALL="yes"
            msg_info "Found existing NetBox Agent installation"
            msg_ok "Will update existing installation"
        fi
    fi
    
    # Transfer and execute installation script
    cat > /tmp/netbox-agent-install.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Update system
apt-get update

# Fix any broken nginx packages from previous installations
if dpkg -l | grep -q "^.i.*nginx"; then
    echo "Removing broken nginx packages from previous installation..."
    apt-get remove --purge -y nginx nginx-common || true
    apt-get autoremove -y || true
fi

apt-get upgrade -y

# Install dependencies
apt-get install -y curl sudo mc git sqlite3 python3 python3-pip python3-venv jq nmap

# Create netbox-agent user
useradd -r -s /bin/bash -d /opt/netbox-agent netbox-agent || true
mkdir -p /opt/netbox-agent
chown -R netbox-agent:netbox-agent /opt/netbox-agent

# Clone NetBox Agent repository
cd /opt/netbox-agent
if [ ! -d ".git" ]; then
    sudo -u netbox-agent git clone https://github.com/festion/netbox-agent.git .
else
    sudo -u netbox-agent git pull origin main
fi

# Set up Python virtual environment
# Remove existing virtual environment if it exists (in case it's corrupted)
if [ -d "venv" ]; then
    echo "Removing existing virtual environment..."
    rm -rf venv
fi

echo "Creating fresh Python virtual environment..."
sudo -u netbox-agent python3 -m venv venv

# Verify virtual environment was created successfully
if [ ! -f "venv/bin/python" ]; then
    echo "ERROR: Virtual environment creation failed"
    exit 1
fi

# Upgrade pip in virtual environment
echo "Upgrading pip in virtual environment..."
sudo -u netbox-agent venv/bin/python -m pip install --upgrade pip

# Create fallback requirements.txt if it doesn't exist
if [ ! -f requirements.txt ]; then
    echo "Creating fallback requirements.txt file..."
    sudo -u netbox-agent cat > requirements.txt << 'REQUIREMENTS'
# NetBox Agent Dependencies

# Core dependencies
requests>=2.31.0
pydantic>=2.0.0
schedule>=1.2.0
python-dotenv>=1.0.0

# Optional dependencies for various data sources
pynetbox>=7.0.0  # NetBox Python API
python-nmap>=0.7.1  # Network scanning
homeassistant-api>=0.1.1  # Home Assistant integration

# Development dependencies
pytest>=7.0.0
pytest-asyncio>=0.21.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0

# Logging and monitoring
structlog>=23.0.0
prometheus-client>=0.17.0
REQUIREMENTS
fi

# Install Python dependencies using the full path to pip
echo "Installing Python dependencies..."
sudo -u netbox-agent venv/bin/python -m pip install -r requirements.txt

# Create production configuration
sudo -u netbox-agent mkdir -p config logs

if [ ! -f config/netbox-agent.json ]; then
    sudo -u netbox-agent cat > config/netbox-agent.json << 'CONFIG'
{
  "netbox": {
    "url": "https://netbox.homelab.local",
    "token": "your-netbox-api-token-here",
    "verify_ssl": true
  },
  "sources": {
    "homeassistant": {
      "enabled": false,
      "url": "http://192.168.1.10:8123",
      "token_path": "/opt/netbox-agent/config/ha_token",
      "sync_interval": 3600
    },
    "network_scan": {
      "enabled": true,
      "networks": ["192.168.1.0/24"],
      "scan_interval": 3600
    },
    "filesystem": {
      "enabled": true,
      "config_paths": ["/etc/network", "/opt/homelab/configs"],
      "watch_interval": 300
    },
    "proxmox": {
      "enabled": false,
      "url": "https://proxmox.homelab.local:8006",
      "username": "api@pve",
      "token": "your-proxmox-token-here"
    },
    "truenas": {
      "enabled": false,
      "url": "https://truenas.homelab.local",
      "api_key": "your-truenas-api-key-here"
    }
  },
  "logging": {
    "level": "INFO",
    "file": "/opt/netbox-agent/logs/netbox-agent.log",
    "max_size": "10MB",
    "backup_count": 5
  },
  "sync": {
    "dry_run": false,
    "full_sync_interval": 86400,
    "incremental_sync_interval": 3600
  }
}
CONFIG
fi

# Create environment file
if [ ! -f /opt/netbox-agent/.env ]; then
    sudo -u netbox-agent cat > /opt/netbox-agent/.env << 'ENVFILE'
# NetBox Agent Environment Configuration
ENVIRONMENT=production
NETBOX_URL=https://netbox.homelab.local
NETBOX_TOKEN=your_netbox_api_token_here
NETBOX_VERIFY_SSL=true
GITHUB_TOKEN=your_github_token_here
HA_URL=http://192.168.1.10:8123
HA_TOKEN=your_ha_token_here
NETWORK_RANGES=192.168.1.0/24
LOG_LEVEL=INFO
LOG_FILE=/opt/netbox-agent/logs/netbox-agent.log
ENVFILE
fi

chown netbox-agent:netbox-agent /opt/netbox-agent/.env
chmod 600 /opt/netbox-agent/.env

# Create systemd service
cat > /etc/systemd/system/netbox-agent.service << 'SYSTEMD'
[Unit]
Description=NetBox Agent - Automated NetBox population service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=netbox-agent
Group=netbox-agent
WorkingDirectory=/opt/netbox-agent
Environment=PATH=/opt/netbox-agent/venv/bin
ExecStart=/opt/netbox-agent/venv/bin/python src/netbox_agent.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=netbox-agent

[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable netbox-agent

# Create a simple health check API using Python HTTP server
sudo -u netbox-agent cat > /opt/netbox-agent/health_server.py << 'HEALTH'
#!/usr/bin/env python3
"""Simple health check HTTP server for NetBox Agent"""

import json
import http.server
import socketserver
import threading
import time
from pathlib import Path

class HealthHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Check if main service is running
            agent_running = Path('/opt/netbox-agent/logs/netbox-agent.log').exists()
            
            response = {
                "status": "healthy" if agent_running else "degraded",
                "service": "netbox-agent",
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "agent_running": agent_running
            }
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {
                "service": "netbox-agent",
                "version": "1.0.0",
                "environment": "production",
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    PORT = 8080
    with socketserver.TCPServer(("", PORT), HealthHandler) as httpd:
        print(f"Health server running on port {PORT}")
        httpd.serve_forever()
HEALTH

chmod +x /opt/netbox-agent/health_server.py

# Create health server systemd service
cat > /etc/systemd/system/netbox-agent-health.service << 'HEALTHSYSTEMD'
[Unit]
Description=NetBox Agent Health Check Server
After=network.target

[Service]
Type=simple
User=netbox-agent
Group=netbox-agent
WorkingDirectory=/opt/netbox-agent
ExecStart=/usr/bin/python3 /opt/netbox-agent/health_server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
HEALTHSYSTEMD

systemctl daemon-reload
systemctl enable netbox-agent-health
systemctl start netbox-agent-health

# Note: This service runs on port 8080 and should be proxied through
# the centralized Nginx Proxy Manager instead of running its own nginx instance

# Clean up
apt-get autoremove -y
apt-get autoclean

echo "NetBox Agent installation completed!"
echo "Please configure /opt/netbox-agent/config/netbox-agent.json with your settings"
echo "Then start the service with: systemctl start netbox-agent"
EOF

    # Execute installation script in container
    pct exec $CTID -- bash < /tmp/netbox-agent-install.sh
    
    # Clean up
    rm /tmp/netbox-agent-install.sh
    
    msg_ok "Installed NetBox Agent"
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
msg_ok "Completed Successfully!"

# Wait a moment for DHCP to assign IP
sleep 5
IP=$(pct exec $CTID -- hostname -I | awk '{print $1}' 2>/dev/null || echo "check container networking")

echo -e "${DGN}NetBox Agent Service Details:${CL}"
echo -e "${DGN}Container ID: ${BL}$CTID${CL}"
if [[ "$IP" != "check container networking" && -n "$IP" ]]; then
    echo -e "${DGN}IP Address: ${BL}$IP${CL}"
    echo -e "${DGN}Health Check: ${BL}http://$IP:8080/health${CL}"
    echo -e "${DGN}Service Status: ${BL}http://$IP:8080/status${CL}"
    echo -e "${YW}Note: Configure this service in Nginx Proxy Manager for external access${CL}"
else
    echo -e "${YW}IP Address: ${BL}Will be assigned by DHCP${CL}"
    echo -e "${YW}Check container networking: ${BL}pct exec $CTID -- hostname -I${CL}"
fi

echo -e "\n${GN}Next Steps:${CL}"
echo -e "1. ${DGN}Configure NetBox settings: ${BL}pct exec $CTID -- nano /opt/netbox-agent/config/netbox-agent.json${CL}"
echo -e "2. ${DGN}Update environment file: ${BL}pct exec $CTID -- nano /opt/netbox-agent/.env${CL}"
echo -e "3. ${DGN}Start NetBox Agent: ${BL}pct exec $CTID -- systemctl start netbox-agent${CL}"
echo -e "4. ${DGN}Add to Nginx Proxy Manager: Forward $IP:8080 for external access${CL}"
echo -e "5. ${DGN}Check service status: ${BL}pct exec $CTID -- systemctl status netbox-agent${CL}"
echo -e "6. ${DGN}View service logs: ${BL}pct exec $CTID -- journalctl -u netbox-agent -f${CL}"
echo -e "7. ${DGN}Container management: ${BL}pct start/stop/restart $CTID${CL}"

echo -e "\n${YW}Configuration Notes:${CL}"
echo -e "- ${DGN}Update NetBox URL and API token in config/netbox-agent.json${CL}"
echo -e "- ${DGN}Configure data sources (Home Assistant, network scanning, etc.)${CL}"
echo -e "- ${DGN}Adjust sync intervals based on your requirements${CL}"
echo -e "- ${DGN}Monitor logs for any configuration issues${CL}"