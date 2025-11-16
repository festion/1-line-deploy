# 1 Line Deploy

One-line deployment scripts for homelab infrastructure components. Deploy production-ready services with a single command.

## 🚀 Available Deployments

### Homepage Dashboard Container

Deploy a production-ready Homepage dashboard for your homelab services and VMs.

**One-line deployment:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/homepage.sh)"
```

**Features:**
- ✅ **Smart Container Detection** - Automatically detects existing containers
- ✅ **Update/Create Modes** - Updates existing installations or creates new containers
- ✅ **Production Ready** - Node.js 20, pnpm, systemd service
- ✅ **Modern UI** - Beautiful, customizable dashboard with dark mode
- ✅ **Service Integration** - Built-in widgets for Docker, Proxmox, monitoring services
- ✅ **Open Source** - Fully open source and actively maintained

**Container Specifications:**
- **CPU:** 2 cores
- **RAM:** 2GB
- **Disk:** 8GB
- **Network:** DHCP (auto-assigned IP)
- **Container ID:** Auto-numbered (150+)
- **OS:** Debian 12 LXC

**Service Endpoints:**
- **Dashboard:** `http://<container-ip>:3000`

**Integration Support:**
- **Proxmox** - VM/container stats and monitoring
- **Uptime Kuma** - Service status monitoring
- **Docker** - Container stats and management
- **Weather, Calendar** - Built-in widgets
- **Custom Services** - Easy YAML configuration

### WikiJS Integration Container

Deploy a production-ready WikiJS integration service for GitOps document management.

**One-line deployment:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/wikijs-integration.sh)"
```

**Features:**
- ✅ **Smart Container Detection** - Automatically detects existing containers
- ✅ **Update/Create Modes** - Updates existing installations or creates new containers  
- ✅ **Production Ready** - Node.js 20, PM2, systemd service, nginx reverse proxy
- ✅ **Auto Configuration** - Pre-configured with WikiJS tokens and endpoints
- ✅ **Health Monitoring** - Built-in health checks and status endpoints

**Container Specifications:**
- **CPU:** 2 cores
- **RAM:** 1GB
- **Disk:** 4GB  
- **Network:** DHCP (auto-assigned IP)
- **Container ID:** Auto-numbered (130+)
- **OS:** Debian 12 LXC

**Service Endpoints:**
- **Main Service:** `http://<container-ip>/`
- **Health Check:** `http://<container-ip>/health`
- **Service Status:** `http://<container-ip>/wiki-agent/status`

### NetBox Agent Container

Deploy a production-ready NetBox Agent for automated infrastructure discovery and population.

**One-line deployment:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"
```

**Features:**
- ✅ **Smart Container Detection** - Automatically detects existing containers
- ✅ **Update/Create Modes** - Updates existing installations or creates new containers
- ✅ **Production Ready** - Python 3, systemd service, nginx reverse proxy
- ✅ **Multi-Source Discovery** - Home Assistant, network scanning, filesystem monitoring
- ✅ **Health Monitoring** - Built-in health checks and status endpoints
- ✅ **MCP Integration** - Model Context Protocol server support

**Container Specifications:**
- **CPU:** 2 cores
- **RAM:** 2GB
- **Disk:** 8GB
- **Network:** DHCP (auto-assigned IP)
- **Container ID:** Auto-numbered (140+)
- **OS:** Debian 12 LXC

**Service Endpoints:**
- **Health Check:** `http://<container-ip>/health`
- **Service Status:** `http://<container-ip>/status`

**Data Sources:**
- **Home Assistant** - IoT devices, sensors, network entities
- **Network Scanning** - Automated device discovery via nmap
- **Filesystem** - Configuration file parsing and monitoring
- **Proxmox** - VM and container inventory (optional)
- **TrueNAS** - Storage systems and shares (optional)

### Proxmox Agent Dashboard

Deploy a production-ready Proxmox cluster monitoring dashboard with real-time metrics and alerts.

**One-line deployment:**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/proxmox-agent.sh)"
```

**Features:**
- ✅ **Smart Container Detection** - Automatically detects existing containers
- ✅ **Update/Create Modes** - Updates existing installations or creates new containers
- ✅ **Real-time Monitoring** - WebSocket-based live updates across all cluster nodes
- ✅ **Alert Management** - View, acknowledge, and manage cluster alerts
- ✅ **Automated Remediation** - Intelligent load balancing and resource optimization
- ✅ **Multi-Node Support** - Monitors 3-node Proxmox cluster (expandable)
- ✅ **Modern UI** - Dark theme responsive interface with live metrics

**Container Specifications:**
- **CPU:** 2 cores
- **RAM:** 2GB
- **Disk:** 8GB
- **Network:** DHCP (auto-assigned IP)
- **Container ID:** Auto-numbered (150+)
- **OS:** Debian 12 LXC

**Service Endpoints:**
- **Dashboard:** `http://<container-ip>`
- **API Docs:** `http://<container-ip>/docs`
- **Health Check:** `http://<container-ip>/api/health`

**Cluster Nodes:**
- **proxmox** (192.168.1.137) - Intel N100, 4c/4t (Primary)
- **proxmox2** (192.168.1.125) - Intel i7-6700, 4c/8t (Worker)
- **proxmox3** (192.168.1.126) - Intel i7-6700, 4c/8t (Worker)

**Monitoring Features:**
- **Cluster Status** - Nodes online/offline, quorum status
- **Resource Metrics** - CPU, memory, disk, load averages per node
- **Alert System** - Warning/critical thresholds with automated actions
- **Load Balancing** - Recommendations for VM/container migration
- **High Availability** - Quorum monitoring and failover support

## 📋 Requirements

- Proxmox VE 8.0 or later
- Internet connection for downloading templates and dependencies
- Sufficient resources:
  - **Homepage Dashboard:** 2 CPU cores, 2GB RAM, 8GB disk space
  - **WikiJS Integration:** 2 CPU cores, 1GB RAM, 4GB disk space
  - **NetBox Agent:** 2 CPU cores, 2GB RAM, 8GB disk space
  - **Proxmox Agent Dashboard:** 2 CPU cores, 2GB RAM, 8GB disk space

## 🔄 Usage Instructions

1. **First Installation:** Run the one-line command on your Proxmox host
2. **Updates:** Re-run the same command - it will detect existing containers and offer update options
3. **Multiple Containers:** The script will find available container IDs automatically (starting from 130)

## 🛠️ Supported Operations

- **Fresh Installation** - Creates new containers with service deployments
- **In-place Updates** - Updates existing installations while preserving data
- **Configuration Management** - Maintains production environment settings
- **Service Management** - Automatic systemd service setup and management

## 🔗 Integration

These deployments integrate with:
- **Homepage Dashboard** - Centralized service launcher and dashboard
- **Proxmox Agent Dashboard** - Cluster monitoring and management
- **WikiJS** (192.168.1.90:3000) - Document management system
- **GitOps Auditor** - Repository monitoring and documentation sync
- **NetBox** - Network infrastructure documentation and IPAM
- **Home Assistant** - IoT device management and automation
- **Nginx Proxy Manager** - Centralized reverse proxy for all services
- **Traefik** - Modern reverse proxy with SSL/TLS support
- **Proxmox VE** - Container lifecycle management and monitoring
- **Uptime Kuma** - Service monitoring and alerting

## 🌐 Network Architecture

All deployed services use a **centralized reverse proxy** (Nginx Proxy Manager or Traefik) for external access:

- **Homepage Dashboard** - Runs on port `3000`, proxy via NPM/Traefik for external access with SSL
- **Proxmox Agent Dashboard** - Runs on port `80`, proxy via Traefik for external access with SSL
- **NetBox Agent** - Runs on port `8080`, proxy via NPM for external access
- **WikiJS Integration** - Runs on port `3001`, proxy via NPM for external access
- **No individual nginx instances** - Services are configured to work with the centralized proxy (except Proxmox Agent which has nginx for local routing)
- **Internal communication** - Services communicate directly via container IPs and ports
- **External access** - All external routing handled through centralized reverse proxy
- **SSL/TLS** - Handled by reverse proxy with Let's Encrypt or custom certificates

## 📊 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitOps        │    │   WikiJS        │    │   WikiJS        │
│   Auditor       │───▶│   Integration   │───▶│   Container     │
│   (Dashboard)   │    │   Service       │    │   (Wiki App)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
     192.168.1.58           <auto-dhcp-ip>          192.168.1.90
```

## 🤝 Contributing

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues, feature requests, or contributions:
- 🐛 **Issues:** [GitHub Issues](https://github.com/festion/1-line-deploy/issues)
- 💡 **Features:** [Feature Requests](https://github.com/festion/1-line-deploy/issues/new)
- 📧 **Contact:** Create an issue for support

## 🔧 Development

### Local Testing
```bash
# Serve scripts locally for testing
cd 1-line-deploy
python3 -m http.server 8080

# Test deployments
bash -c "$(curl -fsSL http://localhost:8080/ct/homepage.sh)"
bash -c "$(curl -fsSL http://localhost:8080/ct/wikijs-integration.sh)"
bash -c "$(curl -fsSL http://localhost:8080/ct/netbox-agent.sh)"
bash -c "$(curl -fsSL http://localhost:8080/ct/proxmox-agent.sh)"
```

### Adding New Deployments
1. Create script in `ct/` directory
2. Follow the naming convention: `service-name.sh`
3. Include update/create mode detection
4. Add documentation to README.md
5. Test thoroughly before submitting PR