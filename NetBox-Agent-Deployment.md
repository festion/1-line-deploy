# NetBox Agent Deployment

The NetBox Agent container provides automated infrastructure discovery and population for NetBox IPAM/DCIM systems. This service continuously monitors various data sources and synchronizes discovered devices, networks, and configurations with your NetBox instance.

## 🎯 Overview

The NetBox Agent is a Python-based service that:

- **Discovers infrastructure automatically** from multiple sources
- **Populates NetBox** with discovered devices, IPs, and configurations
- **Monitors changes continuously** and keeps NetBox synchronized
- **Provides health monitoring** with built-in status endpoints
- **Supports MCP integration** for Model Context Protocol interactions

## 🚀 One-Line Deployment

Deploy the NetBox Agent container with a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"
```

## 📋 Prerequisites

### System Requirements
- **Proxmox VE 8.0+** - Required for container management APIs
- **Available Resources**:
  - **CPU**: 2 cores minimum
  - **RAM**: 2GB minimum
  - **Disk**: 8GB available storage
  - **Network**: DHCP-enabled network segment

### External Dependencies
- **NetBox Instance** - Running NetBox installation with API access
- **API Token** - NetBox API token with appropriate permissions
- **Network Access** - Container must reach NetBox and monitored systems

### Optional Integrations
- **Home Assistant** - For IoT device discovery
- **Proxmox API** - For VM/container inventory
- **TrueNAS API** - For storage system monitoring

## 🔧 Installation Process

### Automatic Container Detection

The deployment script automatically:

1. **Scans for existing containers** - Detects NetBox Agent installations
2. **Offers update options** - Choose between update or new deployment
3. **Finds available container ID** - Auto-assigns ID in range 140-200
4. **Configures networking** - DHCP assignment with automatic detection

### Container Specifications

| Setting | Value | Description |
|---------|-------|-------------|
| **Container ID** | 140-200 | Auto-assigned from available range |
| **Hostname** | `netbox-agent` | Default hostname (customizable) |
| **CPU Cores** | 2 | Dedicated CPU allocation |
| **RAM** | 2048 MB | Memory allocation |
| **Disk Space** | 8 GB | Root filesystem size |
| **Network** | DHCP | Automatic IP assignment |
| **OS** | Debian 12 | LXC container base |
| **Tags** | `netbox;agent;python;automation;infrastructure` | Container metadata |

### Installation Steps

1. **Container Creation**
   - Downloads Debian 12 LXC template
   - Creates unprivileged container with specified resources
   - Configures network with DHCP

2. **System Setup**
   - Updates Debian packages
   - Installs Python 3, pip, virtual environment
   - Installs system dependencies (nmap, sqlite3, nginx)

3. **NetBox Agent Installation**
   - Creates dedicated `netbox-agent` user
   - Clones NetBox Agent repository
   - Sets up Python virtual environment
   - Installs Python dependencies

4. **Service Configuration**
   - Creates systemd service definitions
   - Configures nginx reverse proxy
   - Sets up health check endpoints
   - Initializes logging system

## ⚙️ Configuration

### Primary Configuration File

The main configuration is located at `/opt/netbox-agent/config/netbox-agent.json`:

```json
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
```

### Environment Configuration

The `.env` file at `/opt/netbox-agent/.env` contains sensitive configuration:

```bash
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
```

## 🔌 Data Sources

### Network Scanning
- **Purpose**: Discovers devices via ICMP ping and port scanning
- **Technology**: nmap integration with Python
- **Configuration**: Specify target networks in CIDR notation
- **Frequency**: Configurable scan intervals (default: 1 hour)

### Home Assistant Integration
- **Purpose**: Discovers IoT devices, sensors, and automation entities
- **Requirements**: Home Assistant API token and network access
- **Data Types**: Devices, sensors, switches, lights, climate controls
- **Authentication**: Long-lived access token

### Filesystem Monitoring
- **Purpose**: Parses configuration files for network information
- **Paths**: Monitors specified directories for config changes
- **File Types**: Network configs, service definitions, inventory files
- **Change Detection**: Real-time file system watching

### Proxmox Integration (Optional)
- **Purpose**: Discovers VMs, containers, and host information
- **Requirements**: Proxmox API token with read permissions
- **Data Types**: Virtual machines, containers, networks, storage
- **API Version**: Compatible with Proxmox VE 8.0+

### TrueNAS Integration (Optional)
- **Purpose**: Monitors storage systems and network shares
- **Requirements**: TrueNAS API key with appropriate permissions
- **Data Types**: Storage pools, datasets, network shares
- **Protocols**: REST API integration

## 🌐 Service Endpoints

After deployment, the NetBox Agent provides several HTTP endpoints:

### Health Check Endpoint
```bash
curl http://<container-ip>/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "netbox-agent",
  "timestamp": "2024-01-15T10:30:00Z",
  "agent_running": true
}
```

### Status Endpoint
```bash
curl http://<container-ip>/status
```

**Response:**
```json
{
  "service": "netbox-agent",
  "version": "1.0.0",
  "environment": "production",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## 🚀 Getting Started

### 1. Deploy the Container

Run the one-line deployment command:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"
```

### 2. Initial Configuration

After deployment, configure the NetBox connection:

```bash
# Edit main configuration
pct exec <container-id> -- nano /opt/netbox-agent/config/netbox-agent.json

# Update environment variables
pct exec <container-id> -- nano /opt/netbox-agent/.env
```

**Required Settings:**
- `netbox.url` - Your NetBox instance URL
- `netbox.token` - NetBox API token with write permissions
- `sources.network_scan.networks` - Target networks for scanning

### 3. Start the Service

```bash
# Start the NetBox Agent service
pct exec <container-id> -- systemctl start netbox-agent

# Enable automatic startup
pct exec <container-id> -- systemctl enable netbox-agent

# Check service status
pct exec <container-id> -- systemctl status netbox-agent
```

### 4. Verify Operation

```bash
# Check service logs
pct exec <container-id> -- journalctl -u netbox-agent -f

# Test health endpoint
curl http://<container-ip>/health

# Monitor log file
pct exec <container-id> -- tail -f /opt/netbox-agent/logs/netbox-agent.log
```

## 🔧 Advanced Configuration

### Enabling Home Assistant Integration

1. **Generate Long-Lived Token** in Home Assistant:
   - Profile → Security → Long-Lived Access Tokens
   - Create token with appropriate permissions

2. **Configure Home Assistant Source**:
   ```json
   "homeassistant": {
     "enabled": true,
     "url": "http://192.168.1.10:8123",
     "token_path": "/opt/netbox-agent/config/ha_token",
     "sync_interval": 3600
   }
   ```

3. **Store Token Securely**:
   ```bash
   echo "your_ha_token_here" > /opt/netbox-agent/config/ha_token
   chmod 600 /opt/netbox-agent/config/ha_token
   chown netbox-agent:netbox-agent /opt/netbox-agent/config/ha_token
   ```

### Enabling Proxmox Integration

1. **Create API Token** in Proxmox:
   - Datacenter → Permissions → API Tokens
   - Create token with PVEAuditor role

2. **Configure Proxmox Source**:
   ```json
   "proxmox": {
     "enabled": true,
     "url": "https://proxmox.homelab.local:8006",
     "username": "api@pve",
     "token": "your-proxmox-token-here"
   }
   ```

### Custom Network Ranges

Configure multiple network ranges for comprehensive scanning:

```json
"network_scan": {
  "enabled": true,
  "networks": [
    "192.168.1.0/24",
    "10.0.0.0/24",
    "172.16.0.0/16"
  ],
  "scan_interval": 3600
}
```

## 📊 Monitoring and Maintenance

### Service Management

```bash
# View service status
pct exec <container-id> -- systemctl status netbox-agent

# Restart service
pct exec <container-id> -- systemctl restart netbox-agent

# View recent logs
pct exec <container-id> -- journalctl -u netbox-agent --since "1 hour ago"

# Monitor real-time logs
pct exec <container-id> -- journalctl -u netbox-agent -f
```

### Log Management

```bash
# View application logs
pct exec <container-id> -- tail -f /opt/netbox-agent/logs/netbox-agent.log

# Check log rotation
pct exec <container-id> -- ls -la /opt/netbox-agent/logs/

# Monitor disk usage
pct exec <container-id> -- du -sh /opt/netbox-agent/logs/
```

### Health Monitoring

```bash
# Check health endpoint
curl http://<container-ip>/health

# Monitor service uptime
pct exec <container-id> -- systemctl show netbox-agent --property=ActiveEnterTimestamp

# Check resource usage
pct exec <container-id> -- top -p $(pgrep -f netbox_agent.py)
```

## 🔄 Updates and Maintenance

### Updating the NetBox Agent

Re-run the deployment script to update existing installations:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"
```

The script will:
1. Detect existing container
2. Offer update option
3. Pull latest code from repository
4. Update Python dependencies
5. Restart services

### Manual Updates

```bash
# Connect to container
pct exec <container-id> -- bash

# Switch to netbox-agent user
sudo -u netbox-agent bash

# Navigate to application directory
cd /opt/netbox-agent

# Pull latest changes
git pull origin main

# Update dependencies
source venv/bin/activate
pip install -r requirements.txt

# Restart service
exit
systemctl restart netbox-agent
```

## 🔗 Integration Examples

### NetBox Setup Requirements

Your NetBox instance should have:

1. **API Token** with permissions for:
   - Creating and updating devices
   - Managing IP addresses and networks
   - Creating device types and manufacturers

2. **Basic Site Configuration**:
   - At least one site defined
   - Device roles (server, network, storage)
   - Basic device types

3. **Network Configuration**:
   - IP prefixes for scanned networks
   - VLANs if using tagged networks

### Workflow Integration

The NetBox Agent integrates with the broader homelab ecosystem:

1. **Discovery Phase**:
   - Scans networks for active devices
   - Queries Home Assistant for IoT devices
   - Monitors filesystem for configuration changes

2. **Processing Phase**:
   - Correlates discovered data
   - Identifies device types and roles
   - Maps network relationships

3. **Synchronization Phase**:
   - Creates/updates NetBox objects
   - Maintains IP address assignments
   - Updates device relationships

4. **Monitoring Phase**:
   - Continuous health monitoring
   - Log analysis and reporting
   - Integration with GitOps Auditor

## 🎯 Next Steps

After successful deployment:

1. **Configure NetBox integration** with proper API token and settings
2. **Enable desired data sources** based on your homelab setup
3. **Monitor initial discovery** through logs and NetBox interface
4. **Fine-tune scan intervals** based on your network size and requirements
5. **Set up monitoring** using the health endpoints
6. **Review integration** with other homelab services

For additional help, see the [Troubleshooting](Troubleshooting) guide or [Architecture & Integration](Architecture-Integration) documentation.