#!/usr/bin/env bash

# Proxmox Agent Dashboard Container Deployment
# One-line deployment: bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/proxmox-agent.sh)"

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
CT_NAME="proxmox-agent"
CT_HOSTNAME="proxmox-agent"
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
APP_PORT="8000"
APP_DOMAIN="proxmox-agent.internal.lakehouse.wtf"

# Functions
header_info() {
    clear
    cat <<"EOF"
 ____                                            _                    _
|  _ \ _ __ _____  ___ __ ___   _____  __      / \   __ _  ___ _ __ | |_
| |_) | '__/ _ \ \/ / '_ ` _ \ / _ \ \/ /     / _ \ / _` |/ _ \ '_ \| __|
|  __/| | | (_) >  <| | | | | | (_) >  <     / ___ \ (_| |  __/ | | | |_
|_|   |_|  \___/_/\_\_| |_| |_|\___/_/\_\   /_/   \_\__, |\___|_| |_|\__|
                                                     |___/
       Proxmox Cluster Monitoring Dashboard
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
        if ! pveversion | grep -Eq "pve-manager/[8-9]|pve-manager/[1-9][0-9]"; then
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
    # Check for existing Proxmox Agent containers
    local existing_containers=$(pct list | grep -E "(proxmox-agent|Proxmox-Agent)" | awk '{print $1}')

    if [[ -n "$existing_containers" ]]; then
        echo -e "${YW}Found existing Proxmox Agent container(s):${CL}"
        for container_id in $existing_containers; do
            local container_name=$(pct config $container_id | grep "hostname:" | cut -d' ' -f2)
            local container_status=$(pct status $container_id | cut -d' ' -f2)
            echo -e "  ${BL}ID: $container_id${CL} | ${BL}Name: $container_name${CL} | ${BL}Status: $container_status${CL}"
        done

        echo -e "\n${YW}Would you like to:${CL}"
        echo "  1) Update existing container (${existing_containers})"
        echo "  2) Create a new container"
        echo "  3) Exit"
        read -p "Enter choice [1-3]: " choice

        case $choice in
            1)
                CT_ID="${existing_containers}"
                UPDATE_MODE="yes"
                echo -e "${GN}Will update container ${CT_ID}${CL}"
                ;;
            2)
                echo -e "${GN}Will create new container${CL}"
                UPDATE_MODE="no"
                ;;
            3)
                echo -e "${RD}Exiting...${CL}"
                exit 0
                ;;
            *)
                msg_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

find_next_available_id() {
    local start_id=150
    local max_id=200

    for ((id=start_id; id<=max_id; id++)); do
        if ! pct status $id &>/dev/null; then
            CT_ID=$id
            return 0
        fi
    done

    msg_error "No available container IDs found between $start_id and $max_id"
    exit 1
}

create_container() {
    msg_info "Creating LXC container ${CT_ID}"

    TEMPLATE_SEARCH="debian-12"
    mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($TEMPLATE_SEARCH.*\)/\1/p" | sort -t - -k 2 -V)

    if [ ${#TEMPLATES[@]} -eq 0 ]; then
        msg_error "Unable to find a suitable template"
        exit 1
    fi

    TEMPLATE="${TEMPLATES[-1]}"

    msg_info "Downloading LXC template (if needed)"
    if ! pveam list local | grep -q "$TEMPLATE"; then
        pveam download local $TEMPLATE >/dev/null 2>&1 || {
            msg_error "Failed to download template"
            exit 1
        }
    fi
    msg_ok "Template ready"

    msg_info "Creating LXC container"
    if ! pct create $CT_ID local:vztmpl/${TEMPLATE} \
        -hostname $CT_HOSTNAME \
        -cores $CORE_COUNT \
        -memory $RAM_SIZE \
        -net0 name=eth0,bridge=$BRG,ip=$NET \
        -storage local \
        -rootfs local:${DISK_SIZE} \
        -unprivileged 1 \
        -onboot 1 \
        -features nesting=1 2>&1; then
        msg_error "Failed to create LXC container"
        echo -e "\nTrying with alternate storage configuration..."
        # Try with local-lvm if local fails
        pct create $CT_ID local:vztmpl/${TEMPLATE} \
            -hostname $CT_HOSTNAME \
            -cores $CORE_COUNT \
            -memory $RAM_SIZE \
            -net0 name=eth0,bridge=$BRG,ip=$NET \
            -rootfs local-lvm:${DISK_SIZE} \
            -unprivileged 1 \
            -onboot 1 \
            -features nesting=1 || {
            msg_error "Failed to create container with both storage options"
            exit 1
        }
    fi
    msg_ok "Created LXC container ${CT_ID}"
}

install_proxmox_agent() {
    local container_id=$1

    msg_info "Starting container ${container_id}"
    pct start $container_id
    sleep 3
    msg_ok "Container started"

    msg_info "Installing system dependencies"
    pct exec $container_id -- bash -c "apt-get update && apt-get install -y curl git wget ca-certificates gnupg supervisor nginx sudo python3 python3-pip python3-venv" >/dev/null 2>&1
    msg_ok "System dependencies installed"

    msg_info "Installing Node.js 20.x"
    pct exec $container_id -- bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs" >/dev/null 2>&1
    msg_ok "Node.js installed"

    msg_info "Cloning Proxmox Agent repository"
    pct exec $container_id -- bash -c "rm -rf /opt/proxmox-agent && git clone https://github.com/festion/proxmox-agent.git /opt/proxmox-agent" >/dev/null 2>&1
    msg_ok "Repository cloned"

    msg_info "Installing Python backend dependencies"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent/dashboard/backend && python3 -m pip install --break-system-packages -q -r requirements.txt" >/dev/null 2>&1
    msg_ok "Python dependencies installed"

    msg_info "Installing frontend dependencies"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent/dashboard/frontend && npm install --silent" >/dev/null 2>&1
    msg_ok "Frontend dependencies installed"

    msg_info "Building production frontend"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent/dashboard/frontend && npm run build" >/dev/null 2>&1
    msg_ok "Frontend built"

    msg_info "Creating environment configuration"
    pct exec $container_id -- bash -c "cat > /opt/proxmox-agent/.env << 'EOF'
# Proxmox Agent Dashboard Configuration
PROXMOX_HOST=192.168.1.137
PROXMOX_USER=root

# API Authentication
API_USERNAME=admin
API_PASSWORD=proxmox123

# Server Configuration
PORT=${APP_PORT}
HOST=0.0.0.0

# Cluster nodes
CLUSTER_NODES=proxmox,proxmox2,proxmox3
EOF
" >/dev/null 2>&1
    msg_ok "Environment configured"

    msg_info "Configuring Supervisor for backend"
    pct exec $container_id -- bash -c "cat > /etc/supervisor/conf.d/proxmox-agent-backend.conf << 'EOF'
[program:proxmox-agent-backend]
command=/usr/bin/python3 /opt/proxmox-agent/dashboard/backend/main_mcp.py
directory=/opt/proxmox-agent/dashboard/backend
user=root
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/proxmox-agent-backend.log
environment=PYTHONUNBUFFERED=1
EOF
" >/dev/null 2>&1
    msg_ok "Supervisor configured"

    msg_info "Configuring Nginx for frontend"
    pct exec $container_id -- bash -c "cat > /etc/nginx/sites-available/proxmox-agent << 'EOF'
server {
    listen 80;
    server_name ${APP_DOMAIN} _;

    root /opt/proxmox-agent/dashboard/frontend/dist;
    index index.html;

    # Frontend static files
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API proxy
    location /api {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }
}
EOF
" >/dev/null 2>&1
    msg_ok "Nginx configured"

    msg_info "Enabling services"
    pct exec $container_id -- bash -c "ln -sf /etc/nginx/sites-available/proxmox-agent /etc/nginx/sites-enabled/ && rm -f /etc/nginx/sites-enabled/default" >/dev/null 2>&1
    pct exec $container_id -- bash -c "nginx -t" >/dev/null 2>&1
    msg_ok "Nginx configuration tested"

    msg_info "Starting services"
    pct exec $container_id -- bash -c "supervisorctl reread && supervisorctl update && supervisorctl start proxmox-agent-backend" >/dev/null 2>&1 || true
    pct exec $container_id -- bash -c "systemctl reload nginx" >/dev/null 2>&1
    msg_ok "Services started"

    msg_info "Waiting for services to be ready"
    sleep 5
    msg_ok "Services ready"
}

update_proxmox_agent() {
    local container_id=$1

    msg_info "Updating Proxmox Agent installation"

    if pct status $container_id | grep -q "stopped"; then
        msg_info "Starting stopped container"
        pct start $container_id
        sleep 3
        msg_ok "Container started"
    fi

    msg_info "Stopping services"
    pct exec $container_id -- bash -c "supervisorctl stop proxmox-agent-backend" >/dev/null 2>&1 || true
    msg_ok "Services stopped"

    msg_info "Backing up configuration"
    pct exec $container_id -- bash -c "cp /opt/proxmox-agent/.env /opt/proxmox-agent/.env.backup" >/dev/null 2>&1 || true
    msg_ok "Configuration backed up"

    msg_info "Updating repository"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent && git pull" >/dev/null 2>&1
    msg_ok "Repository updated"

    msg_info "Updating Python dependencies"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent/dashboard/backend && python3 -m pip install --break-system-packages -q -r requirements.txt" >/dev/null 2>&1
    msg_ok "Python dependencies updated"

    msg_info "Updating frontend dependencies"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent/dashboard/frontend && npm install --silent" >/dev/null 2>&1
    msg_ok "Frontend dependencies updated"

    msg_info "Rebuilding frontend"
    pct exec $container_id -- bash -c "cd /opt/proxmox-agent/dashboard/frontend && npm run build" >/dev/null 2>&1
    msg_ok "Frontend rebuilt"

    msg_info "Restarting services"
    pct exec $container_id -- bash -c "supervisorctl reread && supervisorctl update && supervisorctl start proxmox-agent-backend" >/dev/null 2>&1
    pct exec $container_id -- bash -c "systemctl reload nginx" >/dev/null 2>&1
    msg_ok "Services restarted"

    msg_info "Waiting for services to be ready"
    sleep 5
    msg_ok "Update complete"
}

get_container_ip() {
    local container_id=$1
    local ip=""
    local max_attempts=30
    local attempt=0

    msg_info "Waiting for IP address assignment"

    while [ $attempt -lt $max_attempts ]; do
        ip=$(pct exec $container_id -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)

        if [[ -n "$ip" ]]; then
            msg_ok "IP address assigned: ${ip}"
            echo "$ip"
            return 0
        fi

        sleep 2
        ((attempt++))
    done

    msg_error "Failed to get IP address"
    return 1
}

print_completion_message() {
    local container_id=$1
    local ip=$2

    header_info
    echo -e "\n${GN}═══════════════════════════════════════════════════${CL}"
    echo -e "${GN}  Proxmox Agent Dashboard Deployment Complete!${CL}"
    echo -e "${GN}═══════════════════════════════════════════════════${CL}\n"

    echo -e "${BL}Container Details:${CL}"
    echo -e "  ${YW}Container ID:${CL} ${container_id}"
    echo -e "  ${YW}Hostname:${CL} ${CT_HOSTNAME}"
    echo -e "  ${YW}IP Address:${CL} ${ip}"
    echo -e "  ${YW}Resources:${CL} ${CORE_COUNT} cores, ${RAM_SIZE}MB RAM, ${DISK_SIZE}GB disk\n"

    echo -e "${BL}Service Access:${CL}"
    echo -e "  ${YW}Dashboard:${CL} http://${ip}"
    echo -e "  ${YW}API Docs:${CL} http://${ip}/docs"
    echo -e "  ${YW}Health Check:${CL} http://${ip}/api/health\n"

    echo -e "${BL}Default Credentials:${CL}"
    echo -e "  ${YW}Username:${CL} admin"
    echo -e "  ${YW}Password:${CL} proxmox123\n"

    echo -e "${BL}Features:${CL}"
    echo -e "  • Real-time cluster monitoring across 3 nodes"
    echo -e "  • WebSocket-based live updates"
    echo -e "  • Alert management and remediation"
    echo -e "  • Node health and resource tracking"
    echo -e "  • Dark theme responsive interface\n"

    echo -e "${BL}Configuration Files:${CL}"
    echo -e "  ${YW}Environment:${CL} /opt/proxmox-agent/.env"
    echo -e "  ${YW}Backend Log:${CL} /var/log/proxmox-agent-backend.log"
    echo -e "  ${YW}Nginx Config:${CL} /etc/nginx/sites-available/proxmox-agent\n"

    echo -e "${BL}Useful Commands:${CL}"
    echo -e "  ${YW}View logs:${CL} pct exec ${container_id} -- tail -f /var/log/proxmox-agent-backend.log"
    echo -e "  ${YW}Restart backend:${CL} pct exec ${container_id} -- supervisorctl restart proxmox-agent-backend"
    echo -e "  ${YW}Restart nginx:${CL} pct exec ${container_id} -- systemctl restart nginx"
    echo -e "  ${YW}Container shell:${CL} pct enter ${container_id}\n"

    echo -e "${BL}Next Steps:${CL}"
    echo -e "  1. Configure Proxmox credentials in /opt/proxmox-agent/.env"
    echo -e "  2. Set up Traefik reverse proxy for SSL access"
    echo -e "  3. Create DHCP reservation for static IP"
    echo -e "  4. Add to Uptime Kuma monitoring"
    echo -e "  5. Add to Homepage dashboard\n"

    echo -e "${BL}Cluster Nodes:${CL}"
    echo -e "  ${YW}proxmox:${CL}  192.168.1.137 (Primary)"
    echo -e "  ${YW}proxmox2:${CL} 192.168.1.125 (Worker)"
    echo -e "  ${YW}proxmox3:${CL} 192.168.1.126 (Worker)\n"

    echo -e "${BL}Documentation:${CL}"
    echo -e "  ${YW}Quick Start:${CL} https://github.com/festion/proxmox-agent/blob/main/QUICKSTART.md"
    echo -e "  ${YW}Dashboard Docs:${CL} https://github.com/festion/proxmox-agent/blob/main/dashboard/DASHBOARD_README.md"
    echo -e "  ${YW}Full README:${CL} https://github.com/festion/proxmox-agent/blob/main/README.md\n"

    echo -e "${GN}═══════════════════════════════════════════════════${CL}\n"
}

# Main execution
main() {
    header_info
    start_routine
    check_existing_container

    if [[ "$UPDATE_MODE" == "yes" ]]; then
        update_proxmox_agent $CT_ID
        IP=$(get_container_ip $CT_ID)
        print_completion_message $CT_ID $IP
    else
        if [[ -z "$CT_ID" ]]; then
            find_next_available_id
        fi

        create_container
        install_proxmox_agent $CT_ID
        IP=$(get_container_ip $CT_ID)
        print_completion_message $CT_ID $IP
    fi
}

main "$@"
