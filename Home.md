# 1-Line Deploy - Home

Welcome to the **1-Line Deploy** project wiki. This project provides one-line deployment scripts for homelab infrastructure components, allowing you to deploy production-ready services with a single command on Proxmox VE.

## 🎯 Project Overview

The 1-Line Deploy project simplifies the deployment of essential homelab infrastructure services by automating the complete setup process - from container creation to service configuration. Each deployment includes:

- **Smart Container Detection** - Automatically detects existing installations
- **Update/Create Modes** - Updates existing services or creates new containers
- **Production-Ready Configuration** - Pre-configured with best practices
- **Health Monitoring** - Built-in health checks and status endpoints
- **DHCP Network Configuration** - Automatic IP assignment and network setup

## 🚀 Available Deployments

### [NetBox Agent Container](NetBox-Agent-Deployment)
Deploy a production-ready NetBox Agent for automated infrastructure discovery and population.

- **Purpose**: Automated infrastructure discovery and NetBox population
- **Technology**: Python 3, systemd service, nginx reverse proxy
- **Resources**: 2 CPU cores, 2GB RAM, 8GB disk
- **Container ID Range**: 140-200
- **Data Sources**: Home Assistant, network scanning, filesystem monitoring, Proxmox, TrueNAS

**One-line deployment:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"
```

### [WikiJS Integration Container](WikiJS-Integration-Deployment)
Deploy a production-ready WikiJS integration service for GitOps document management.

- **Purpose**: GitOps document management and WikiJS integration
- **Technology**: Node.js 20, PM2, systemd service, nginx reverse proxy
- **Resources**: 2 CPU cores, 1GB RAM, 4GB disk
- **Container ID Range**: 130-200
- **Features**: Auto-configuration, health monitoring, GitOps auditor integration

**One-line deployment:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/wikijs-integration.sh)"
```

## 📋 Prerequisites

Before using these deployment scripts, ensure you have:

### System Requirements
- **Proxmox VE 8.0 or later** - The scripts require specific Proxmox APIs
- **Internet connection** - For downloading templates and dependencies
- **Available resources**:
  - NetBox Agent: 2 CPU cores, 2GB RAM, 8GB disk space
  - WikiJS Integration: 2 CPU cores, 1GB RAM, 4GB disk space

### Network Requirements
- **DHCP-enabled network** - Containers will receive automatic IP assignment
- **Internet access** - For downloading Node.js, Python packages, and system updates
- **DNS resolution** - For accessing external repositories and services

### Storage Requirements
- **Local LVM storage** - Default storage for container root filesystems
- **Available container IDs** - Scripts automatically find available IDs in designated ranges

## 🔄 Usage Patterns

### First-Time Installation
1. Copy and paste the one-line command on your Proxmox host
2. The script will detect no existing containers and proceed with creation
3. Wait for the automated installation to complete
4. Configure the deployed service using the provided endpoints

### Updating Existing Installations
1. Re-run the same one-line command
2. The script will detect existing containers and offer update options
3. Choose to update existing or create new container
4. Updates preserve existing configuration and data

### Multiple Deployments
- Scripts automatically find available container IDs
- NetBox Agent containers start from ID 140
- WikiJS Integration containers start from ID 130
- No manual ID management required

## 🛠️ Service Management

### Container Operations
```bash
# Start a container
pct start <container-id>

# Stop a container
pct stop <container-id>

# Restart a container
pct restart <container-id>

# Check container status
pct status <container-id>

# Execute commands in container
pct exec <container-id> -- <command>
```

### Service Operations
```bash
# Check service status
pct exec <container-id> -- systemctl status <service-name>

# View service logs
pct exec <container-id> -- journalctl -u <service-name> -f

# Restart service
pct exec <container-id> -- systemctl restart <service-name>
```

## 🔗 Integration Ecosystem

These deployments integrate seamlessly with common homelab infrastructure:

- **[WikiJS](https://wiki.homelab.local)** (192.168.1.90:3000) - Document management system
- **[NetBox](https://netbox.homelab.local)** - Network infrastructure documentation and IPAM
- **[Home Assistant](https://ha.homelab.local)** (192.168.1.10:8123) - IoT device management
- **[GitOps Auditor](https://gitops.homelab.local)** (192.168.1.58) - Repository monitoring
- **Proxmox VE** - Container lifecycle management

## 📚 Documentation Navigation

| Page | Description |
|------|-------------|
| **[NetBox Agent Deployment](NetBox-Agent-Deployment)** | Complete setup guide for NetBox Agent container |
| **[WikiJS Integration Deployment](WikiJS-Integration-Deployment)** | Detailed WikiJS Integration deployment instructions |
| **[Troubleshooting](Troubleshooting)** | Common issues, solutions, and FAQ |
| **[Architecture & Integration](Architecture-Integration)** | System architecture and integration details |

## 🤝 Contributing

We welcome contributions to improve the deployment scripts and documentation:

1. **Fork the repository** - Create your own fork of the project
2. **Create feature branch** - `git checkout -b feature/AmazingFeature`
3. **Commit changes** - `git commit -m 'Add some AmazingFeature'`
4. **Push to branch** - `git push origin feature/AmazingFeature`
5. **Open Pull Request** - Submit your changes for review

## 🆘 Getting Help

If you encounter issues or need assistance:

- **📖 [Troubleshooting Guide](Troubleshooting)** - Check common issues and solutions
- **🐛 [GitHub Issues](https://github.com/festion/1-line-deploy/issues)** - Report bugs or request features
- **💡 [Feature Requests](https://github.com/festion/1-line-deploy/issues/new)** - Suggest new deployments or improvements
- **📧 [Support](https://github.com/festion/1-line-deploy/issues)** - Create an issue for general support

## 🎯 Quick Start Guide

1. **Choose your deployment** from the available options above
2. **Verify prerequisites** ensure Proxmox VE 8.0+ and sufficient resources
3. **Run the one-line command** directly on your Proxmox host
4. **Follow the setup prompts** for any interactive configuration
5. **Access your service** using the provided IP address and endpoints
6. **Configure the service** according to your homelab requirements

Ready to get started? Choose a deployment from the links above and follow the detailed setup instructions!