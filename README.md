# 1 Line Deploy

One-line deployment scripts for homelab infrastructure components. Deploy production-ready services with a single command.

## 🚀 Available Deployments

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

## 📋 Requirements

- Proxmox VE 8.0 or later
- Internet connection for downloading templates and dependencies
- Sufficient resources (2 CPU cores, 1GB RAM, 4GB disk space)

## 🔄 Usage Instructions

1. **First Installation:** Run the one-line command on your Proxmox host
2. **Updates:** Re-run the same command - it will detect existing containers and offer update options
3. **Multiple Containers:** The script will find available container IDs automatically (starting from 130)

## 🛠️ Supported Operations

- **Fresh Installation** - Creates new container with WikiJS integration
- **In-place Updates** - Updates existing installations while preserving data
- **Configuration Management** - Maintains production environment settings
- **Service Management** - Automatic systemd service setup and management

## 🔗 Integration

This script integrates with:
- **WikiJS** (192.168.1.90:3000) - Document management system
- **GitOps Auditor** - Repository monitoring and documentation sync
- **Proxmox VE** - Container lifecycle management

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

# Test deployment
bash -c "$(curl -fsSL http://localhost:8080/ct/wikijs-integration.sh)"
```

### Adding New Deployments
1. Create script in `ct/` directory
2. Follow the naming convention: `service-name.sh`
3. Include update/create mode detection
4. Add documentation to README.md
5. Test thoroughly before submitting PR