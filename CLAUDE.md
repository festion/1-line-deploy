# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

1-line-deploy is a collection of one-line deployment scripts for homelab infrastructure components. It provides automated deployment of production-ready services on Proxmox VE with minimal user interaction.

## Project Structure

```
1-line-deploy/
├── ct/                     # Container deployment scripts
│   └── wikijs-integration.sh  # WikiJS integration container deployment
├── README.md              # Main documentation
└── LICENSE               # MIT license
```

## Core Architecture

### Deployment Scripts (`/ct/`)

Each deployment script follows a standard pattern:
- **Smart container detection** - Automatically detects existing containers
- **Update/Create modes** - Handles both new installations and updates
- **Production configuration** - Includes systemd services, nginx proxies, PM2 process management
- **Auto-numbering** - Finds available container IDs (starting from 130)

### WikiJS Integration Container

The main deployment creates a complete Node.js environment:
- **Container specs**: 2 CPU cores, 1GB RAM, 4GB disk, Debian 12 LXC
- **Services**: Express.js API on port 3001, nginx reverse proxy on port 80
- **Process management**: PM2 with ecosystem configuration
- **Endpoints**: 
  - `/health` - Service health check
  - `/wiki-agent/status` - Service status information

## Development Commands

### Local Testing
```bash
# Serve scripts locally for testing
cd 1-line-deploy
python3 -m http.server 8080

# Test deployment with local server
bash -c "$(curl -fsSL http://localhost:8080/ct/wikijs-integration.sh)"
```

### Container Management
```bash
# Check container status
pct status <container-id>

# View service logs
pct exec <container-id> -- journalctl -u wikijs-integration -f

# Container operations
pct start/stop/restart <container-id>
```

## Deployment Process

1. **Container Detection**: Scripts check for existing containers by name/hostname
2. **Mode Selection**: User chooses between update existing or create new
3. **ID Assignment**: Auto-finds available container IDs (130-200 range)
4. **Container Creation**: Uses Debian 12 template with specified resources
5. **Service Installation**: Installs Node.js 20, PM2, nginx, and application code
6. **Configuration**: Sets up production environment, systemd service, and reverse proxy

## Key Integration Points

- **WikiJS**: Connects to WikiJS instance at 192.168.1.90:3000
- **GitOps Auditor**: Integrates with homelab GitOps auditing system
- **Proxmox VE**: Requires PVE 8.0+ for container management
- **DHCP Networking**: Uses automatic IP assignment via vmbr0 bridge

## Environment Configuration

Scripts include production-ready configuration:
- Environment variables in `/opt/wikijs-integration/production.env`
- PM2 ecosystem configuration for process management
- Systemd service for system integration
- Nginx reverse proxy for HTTP access
- SQLite database initialization

## Security Considerations

- Containers run unprivileged
- Dedicated service user (`wikijs-integration`)
- Environment files have restricted permissions (600)
- WikiJS API tokens embedded in deployment (production environment)