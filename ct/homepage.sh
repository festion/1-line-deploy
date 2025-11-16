#!/usr/bin/env bash

# Homepage Dashboard Container Deployment
# One-line deployment: bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/homepage.sh)"

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
CT_NAME="homepage"
CT_HOSTNAME="homepage"
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
 _   _
| | | | ___  _ __ ___   ___ _ __   __ _  __ _  ___
| |_| |/ _ \| '_ ` _ \ / _ \ '_ \ / _` |/ _` |/ _ \
|  _  | (_) | | | | | |  __/ |_) | (_| | (_| |  __/
|_| |_|\___/|_| |_| |_|\___| .__/ \__,_|\__, |\___|
                           |_|          |___/

         Homelab Dashboard Deployment
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
    # Check for existing Homepage containers
    local existing_containers=$(pct list | grep -E "(homepage|Homepage)" | awk '{print $1}')

    if [[ -n "$existing_containers" ]]; then
        echo -e "${YW}Found existing Homepage container(s):${CL}"
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
            -features nesting=1 || {
            msg_error "Failed to create container with both storage options"
            exit 1
        }
    fi
    msg_ok "Created LXC container ${CT_ID}"
}

install_homepage() {
    local container_id=$1

    msg_info "Starting container ${container_id}"
    pct start $container_id
    sleep 3
    msg_ok "Container started"

    msg_info "Installing system dependencies"
    pct exec $container_id -- bash -c "apt-get update && apt-get install -y curl git build-essential" >/dev/null 2>&1
    msg_ok "System dependencies installed"

    msg_info "Installing Node.js 20.x"
    pct exec $container_id -- bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs" >/dev/null 2>&1
    msg_ok "Node.js installed"

    msg_info "Creating homepage user"
    pct exec $container_id -- bash -c "useradd -m -s /bin/bash homepage" >/dev/null 2>&1
    msg_ok "Homepage user created"

    msg_info "Installing pnpm"
    pct exec $container_id -- bash -c "npm install -g pnpm" >/dev/null 2>&1
    msg_ok "pnpm installed"

    msg_info "Cloning Homepage repository"
    pct exec $container_id -- bash -c "su - homepage -c 'git clone https://github.com/gethomepage/homepage.git'" >/dev/null 2>&1
    msg_ok "Homepage cloned"

    msg_info "Installing Homepage dependencies"
    pct exec $container_id -- bash -c "su - homepage -c 'cd homepage && pnpm install'" >/dev/null 2>&1
    msg_ok "Dependencies installed"

    msg_info "Building Homepage"
    pct exec $container_id -- bash -c "su - homepage -c 'cd homepage && pnpm build'" >/dev/null 2>&1
    msg_ok "Homepage built"

    msg_info "Creating configuration directory"
    pct exec $container_id -- bash -c "su - homepage -c 'mkdir -p /home/homepage/homepage/config'" >/dev/null 2>&1
    msg_ok "Configuration directory created"

    msg_info "Creating default configuration files"
    pct exec $container_id -- bash -c "cat > /home/homepage/homepage/config/settings.yaml << 'EOF'
---
title: Homelab Dashboard
background: https://images.unsplash.com/photo-1502790671504-542ad42d5189
theme: dark
color: slate
target: _blank
headerStyle: boxed

layout:
  Proxmox:
    style: row
    columns: 3
  Monitoring:
    style: row
    columns: 3
  Network:
    style: row
    columns: 3
  Home Automation:
    style: row
    columns: 3
EOF
" >/dev/null 2>&1

    pct exec $container_id -- bash -c "cat > /home/homepage/homepage/config/services.yaml << 'EOF'
---
# Proxmox Infrastructure
- Proxmox:
    - Proxmox VE:
        icon: proxmox.png
        href: https://proxmox.yourdomain.com:8006
        description: Virtualization Platform

# Monitoring Services
- Monitoring:
    - Uptime Kuma:
        icon: uptime-kuma.png
        href: https://uptime.yourdomain.com
        description: Service Monitoring

    - NetBox:
        icon: netbox.png
        href: https://netbox.yourdomain.com
        description: IPAM & DCIM

# Network Services
- Network:
    - Traefik:
        icon: traefik.png
        href: https://traefik.yourdomain.com
        description: Reverse Proxy

    - Nginx Proxy Manager:
        icon: nginx-proxy-manager.png
        href: https://npm.yourdomain.com
        description: Reverse Proxy Manager

# Home Automation
- Home Automation:
    - Home Assistant:
        icon: home-assistant.png
        href: https://ha.yourdomain.com
        description: Home Automation Platform
EOF
" >/dev/null 2>&1

    pct exec $container_id -- bash -c "cat > /home/homepage/homepage/config/widgets.yaml << 'EOF'
---
# Example widgets - customize as needed
# - search:
#     provider: google
#     target: _blank
EOF
" >/dev/null 2>&1

    pct exec $container_id -- bash -c "chown -R homepage:homepage /home/homepage/homepage/config" >/dev/null 2>&1
    msg_ok "Default configuration created"

    msg_info "Creating systemd service"
    pct exec $container_id -- bash -c "cat > /etc/systemd/system/homepage.service << 'EOF'
[Unit]
Description=Homepage Dashboard
After=network.target

[Service]
Type=simple
User=homepage
WorkingDirectory=/home/homepage/homepage
ExecStart=/usr/bin/pnpm start
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=HOMEPAGE_ALLOWED_HOSTS=*

[Install]
WantedBy=multi-user.target
EOF
" >/dev/null 2>&1
    msg_ok "Systemd service created"

    msg_info "Enabling and starting Homepage service"
    pct exec $container_id -- bash -c "systemctl daemon-reload && systemctl enable homepage && systemctl start homepage" >/dev/null 2>&1
    msg_ok "Homepage service started"

    msg_info "Waiting for service to be ready"
    sleep 5
    msg_ok "Service ready"
}

update_homepage() {
    local container_id=$1

    msg_info "Updating Homepage installation"

    if pct status $container_id | grep -q "stopped"; then
        msg_info "Starting stopped container"
        pct start $container_id
        sleep 3
        msg_ok "Container started"
    fi

    msg_info "Stopping Homepage service"
    pct exec $container_id -- bash -c "systemctl stop homepage" >/dev/null 2>&1 || true
    msg_ok "Service stopped"

    msg_info "Backing up current configuration"
    pct exec $container_id -- bash -c "su - homepage -c 'cp -r /home/homepage/homepage/config /home/homepage/config.backup'" >/dev/null 2>&1 || true
    msg_ok "Configuration backed up"

    msg_info "Updating Homepage repository"
    pct exec $container_id -- bash -c "su - homepage -c 'cd homepage && git pull'" >/dev/null 2>&1
    msg_ok "Repository updated"

    msg_info "Installing dependencies"
    pct exec $container_id -- bash -c "su - homepage -c 'cd homepage && pnpm install'" >/dev/null 2>&1
    msg_ok "Dependencies updated"

    msg_info "Building Homepage"
    pct exec $container_id -- bash -c "su - homepage -c 'cd homepage && pnpm build'" >/dev/null 2>&1
    msg_ok "Homepage rebuilt"

    msg_info "Starting Homepage service"
    pct exec $container_id -- bash -c "systemctl start homepage" >/dev/null 2>&1
    msg_ok "Service started"

    msg_info "Waiting for service to be ready"
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
    echo -e "${GN}     Homepage Dashboard Deployment Complete!${CL}"
    echo -e "${GN}═══════════════════════════════════════════════════${CL}\n"

    echo -e "${BL}Container Details:${CL}"
    echo -e "  ${YW}Container ID:${CL} ${container_id}"
    echo -e "  ${YW}Hostname:${CL} ${CT_HOSTNAME}"
    echo -e "  ${YW}IP Address:${CL} ${ip}"
    echo -e "  ${YW}Resources:${CL} ${CORE_COUNT} cores, ${RAM_SIZE}MB RAM, ${DISK_SIZE}GB disk\n"

    echo -e "${BL}Service Access:${CL}"
    echo -e "  ${YW}Dashboard:${CL} http://${ip}:3000"
    echo -e "  ${YW}Configuration:${CL} /home/homepage/homepage/config/\n"

    echo -e "${BL}Configuration Files:${CL}"
    echo -e "  ${YW}Services:${CL} config/services.yaml"
    echo -e "  ${YW}Settings:${CL} config/settings.yaml"
    echo -e "  ${YW}Widgets:${CL} config/widgets.yaml\n"

    echo -e "${BL}Useful Commands:${CL}"
    echo -e "  ${YW}View logs:${CL} pct exec ${container_id} -- journalctl -u homepage -f"
    echo -e "  ${YW}Restart service:${CL} pct exec ${container_id} -- systemctl restart homepage"
    echo -e "  ${YW}Edit config:${CL} pct exec ${container_id} -- nano /home/homepage/homepage/config/services.yaml"
    echo -e "  ${YW}Container shell:${CL} pct enter ${container_id}\n"

    echo -e "${BL}Next Steps:${CL}"
    echo -e "  1. Configure your services in config/services.yaml"
    echo -e "  2. Customize settings in config/settings.yaml"
    echo -e "  3. Set up Traefik reverse proxy for SSL access"
    echo -e "  4. Add authentication via Traefik middleware\n"

    echo -e "${BL}Documentation:${CL}"
    echo -e "  ${YW}Homepage Docs:${CL} https://gethomepage.dev/latest/"
    echo -e "  ${YW}Widget Config:${CL} https://gethomepage.dev/latest/widgets/\n"

    echo -e "${GN}═══════════════════════════════════════════════════${CL}\n"
}

# Main execution
main() {
    header_info
    start_routine
    check_existing_container

    if [[ "$UPDATE_MODE" == "yes" ]]; then
        update_homepage $CT_ID
        IP=$(get_container_ip $CT_ID)
        print_completion_message $CT_ID $IP
    else
        if [[ -z "$CT_ID" ]]; then
            find_next_available_id
        fi

        create_container
        install_homepage $CT_ID
        IP=$(get_container_ip $CT_ID)
        print_completion_message $CT_ID $IP
    fi
}

main "$@"
