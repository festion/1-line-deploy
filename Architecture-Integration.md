# Architecture & Integration

This document provides a comprehensive overview of the 1-Line Deploy project architecture, system integration patterns, and how the deployed services fit into broader homelab infrastructure ecosystems.

## 🏗️ System Architecture Overview

The 1-Line Deploy project follows a modular, container-based architecture designed for homelab environments. Each deployment creates self-contained, production-ready services that integrate seamlessly with existing infrastructure.

### Core Architecture Principles

- **Container Isolation**: Each service runs in dedicated LXC containers
- **Service Independence**: Services can operate independently while supporting integration
- **Production Ready**: Full production configurations with monitoring and logging
- **Network Integration**: DHCP-based networking with reverse proxy support
- **State Management**: Persistent storage for configuration and data
- **Health Monitoring**: Built-in health checks and status endpoints

## 🔧 Container Infrastructure

### Proxmox VE Foundation

```
┌─────────────────────────────────────────────────────────────────┐
│                        Proxmox VE Host                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   NetBox Agent  │  │WikiJS Integration│  │  Other Services │ │
│  │   Container     │  │   Container      │  │   Containers    │ │
│  │   ID: 140-200   │  │   ID: 130-200    │  │   ID: Various   │ │
│  │   Debian 12     │  │   Debian 12      │  │   Multiple OS   │ │
│  │   Python 3      │  │   Node.js 20     │  │   Technologies  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                      Network Bridge (vmbr0)                    │
├─────────────────────────────────────────────────────────────────┤
│                     Storage (local-lvm)                        │
└─────────────────────────────────────────────────────────────────┘
```

### Container Specifications Comparison

| Component | NetBox Agent | WikiJS Integration |
|-----------|--------------|-------------------|
| **Base OS** | Debian 12 LXC | Debian 12 LXC |
| **Runtime** | Python 3 + venv | Node.js 20 + PM2 |
| **CPU Cores** | 2 | 2 |
| **Memory** | 2GB | 1GB |
| **Storage** | 8GB | 4GB |
| **Container ID Range** | 140-200 | 130-200 |
| **Primary Port** | 8080 (health) | 3001 (service) |
| **Reverse Proxy** | nginx | nginx |
| **Process Manager** | systemd | PM2 + systemd |
| **Database** | N/A | SQLite |

## 🌐 Network Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        Home Network                            │
│                      192.168.1.0/24                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Router     │  │    DHCP      │  │   DNS Server │         │
│  │ 192.168.1.1  │  │   Server     │  │ 192.168.1.1  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Proxmox Host │  │   WikiJS     │  │   NetBox     │         │
│  │192.168.1.xxx │  │192.168.1.90  │  │192.168.1.xxx │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │NetBox Agent  │  │WikiJS Intgr. │  │Home Assistant│         │
│  │192.168.1.xxx │  │192.168.1.xxx │  │192.168.1.10  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

### Port Allocation Strategy

| Service | Internal Port | External Access | Protocol | Purpose |
|---------|---------------|-----------------|----------|---------|
| **NetBox Agent** | 8080 | HTTP | REST | Health checks, status |
| **WikiJS Integration** | 3001 | HTTP | REST/WebSocket | Main service, API |
| **nginx (Both)** | 80 | HTTP | Web | Reverse proxy |
| **SSH (Optional)** | 22 | SSH | TCP | Remote administration |

### Service Discovery

Containers use DHCP for automatic IP assignment, enabling:
- **Dynamic networking** without manual IP management
- **Service registration** through DNS or service discovery
- **Load balancing** capabilities for multiple instances
- **Network isolation** through Proxmox VE networking

## 🔄 Data Flow Architecture

### NetBox Agent Data Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │    │  NetBox Agent   │    │     NetBox      │
│                 │    │   Container     │    │    Instance     │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│• Network Scan   │───▶│• Data Collection│───▶│• Device Storage │
│• Home Assistant │    │• Data Processing│    │• IP Management  │
│• Filesystem     │    │• API Integration│    │• Relationship   │
│• Proxmox API    │    │• Sync Logic     │    │  Mapping        │
│• TrueNAS API    │    │• Health Monitor │    │• Web Interface  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        └─── Continuous Discovery ───────▶ Real-time Sync ─┘
```

### WikiJS Integration Data Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Git Repository │    │WikiJS Integration│    │     WikiJS      │
│                 │    │   Container      │    │   Instance      │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│• Documentation  │───▶│• Content Sync   │───▶│• Page Creation  │
│• Configuration  │    │• Format Convert │    │• Content Update │
│• Templates      │    │• API Integration│    │• Version Control│
│• Automation     │    │• Webhook Handle │    │• User Interface │
│• Scripts        │    │• Health Monitor │    │• Search Index   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        └─── GitOps Workflow ────────▶ Documentation Sync ─┘
```

## 🔗 Integration Patterns

### HomeAssistant Integration

The NetBox Agent integrates with Home Assistant for IoT device discovery:

```yaml
# Home Assistant Configuration
homeassistant:
  # NetBox Agent discovers these entities
  entities:
    - sensors
    - switches  
    - lights
    - climate_controls
    - media_players
    - automation_scripts

# Integration Flow:
# HA API → NetBox Agent → Device Processing → NetBox IPAM
```

**Authentication Flow**:
1. Generate Long-Lived Access Token in Home Assistant
2. Store token in NetBox Agent configuration
3. NetBox Agent polls HA API for entity updates
4. Discovered entities are mapped to NetBox device types

### NetBox IPAM Integration

NetBox serves as the central IPAM (IP Address Management) system:

```
┌─────────────────────────────────────────────────────────────────┐
│                        NetBox IPAM                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Sites     │  │   Racks     │  │   Devices   │            │
│  │ • Homelab   │  │ • Rack-01   │  │ • Servers   │            │
│  │ • Remote    │  │ • Rack-02   │  │ • Network   │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ IP Prefixes │  │  VLANs      │  │ Connections │            │
│  │192.168.1.0  │  │ • VLAN-10   │  │ • Cables    │            │
│  │  /24        │  │ • VLAN-20   │  │ • Interfaces│            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### GitOps Documentation Workflow

WikiJS Integration enables GitOps-driven documentation:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│ Git Repository  │    │  GitOps         │    │    WikiJS       │
│                 │    │  Auditor        │    │                 │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│• README.md      │───▶│• Change Detection│───▶│• Auto-generated │
│• Documentation  │    │• Sync Triggers  │    │  Pages          │
│• Configuration  │    │• Format Convert │    │• Navigation     │
│• Architecture   │    │• Content Valid  │    │• Search Index   │
│• Procedures     │    │• Webhook Handle │    │• Version Hist   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        └──── Push to Git ───────┼────▶ Webhook Trigger ──┘
                                 │
                    ┌─────────────────┐
                    │WikiJS Integration│
                    │   Container      │
                    ├─────────────────┤
                    │• Webhook Server │
                    │• Content Process│
                    │• API Integration│
                    │• Format Convert │
                    └─────────────────┘
```

## 🎯 Service Orchestration

### Startup Dependencies

```
Proxmox VE Boot
       │
       ▼
Container Auto-Start (if enabled)
       │
       ├─── NetBox Agent Container
       │    ├─── System Services (systemd)
       │    ├─── Python Virtual Environment
       │    ├─── NetBox Agent Service
       │    └─── nginx Reverse Proxy
       │
       └─── WikiJS Integration Container
            ├─── System Services (systemd)
            ├─── Node.js Runtime
            ├─── PM2 Process Manager
            ├─── WikiJS Integration Service
            └─── nginx Reverse Proxy
```

### Health Check Orchestration

Both services implement comprehensive health monitoring:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Health Check Flow                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  External Monitor                                              │
│       │                                                        │
│       ▼                                                        │
│  ┌─────────────┐                ┌─────────────┐               │
│  │   NetBox    │                │   WikiJS    │               │
│  │   Agent     │                │Integration  │               │
│  │             │                │             │               │
│  │ /health ────┼─── HTTP 200 ──▶│ /health ────┼─── HTTP 200   │
│  │ /status     │                │ /wiki-agent/│               │
│  │             │                │  status     │               │
│  └─────────────┘                └─────────────┘               │
│       │                                  │                    │
│       ▼                                  ▼                    │
│  ┌─────────────┐                ┌─────────────┐               │
│  │ SystemD     │                │ PM2 Status  │               │
│  │ Service     │                │ + SystemD   │               │
│  │ Monitor     │                │ Monitor     │               │
│  └─────────────┘                └─────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

## 🔒 Security Architecture

### Container Security Model

```
┌─────────────────────────────────────────────────────────────────┐
│                      Security Layers                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Proxmox    │  │ Container   │  │ Application │            │
│  │  Security   │  │ Isolation   │  │  Security   │            │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤            │
│  │• Firewall   │  │• Unprivileged│  │• Service    │            │
│  │• VPN Access │  │  Containers │  │  Users      │            │
│  │• SSH Keys   │  │• Resource   │  │• File       │            │
│  │• TLS Certs  │  │  Limits     │  │  Permissions│            │
│  │• Network    │  │• AppArmor   │  │• API Tokens │            │
│  │  Segmentation│  │• Seccomp    │  │• Secrets    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### Authentication & Authorization

**NetBox Agent**:
- **NetBox API Token**: Write permissions for device/IP management
- **Home Assistant Token**: Long-lived access token (read-only recommended)
- **File Permissions**: Restrictive permissions on config files (600)
- **Service User**: Dedicated `netbox-agent` user with minimal privileges

**WikiJS Integration**:
- **WikiJS JWT Token**: API access with page creation/modification rights
- **Environment Security**: Sensitive tokens in protected .env files
- **Process Isolation**: Runs under dedicated `wikijs-integration` user
- **Database Security**: SQLite with proper file ownership

### Network Security

```
┌─────────────────────────────────────────────────────────────────┐
│                     Network Security                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Internet ───┐                                                 │
│              │                                                 │
│  ┌───────────▼──────────┐                                      │
│  │     Firewall/NAT     │                                      │
│  │   (Router/PFSense)   │                                      │
│  └───────────┬──────────┘                                      │
│              │                                                 │
│  ┌───────────▼──────────┐                                      │
│  │    Home Network      │                                      │
│  │   192.168.1.0/24     │                                      │
│  └───────────┬──────────┘                                      │
│              │                                                 │
│  ┌───────────▼──────────┐                                      │
│  │   Proxmox Network    │                                      │
│  │     (vmbr0)          │                                      │
│  └───────────┬──────────┘                                      │
│              │                                                 │
│  ┌───────────▼──────────┐                                      │
│  │  Container Network   │                                      │
│  │  (Individual IPs)    │                                      │
│  └──────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Monitoring & Observability

### Logging Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Logging Flow                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Application Logs                                              │
│       │                                                        │
│       ▼                                                        │
│  ┌─────────────┐                ┌─────────────┐               │
│  │   NetBox    │                │   WikiJS    │               │
│  │   Agent     │                │Integration  │               │
│  │             │                │             │               │
│  │ netbox-     │                │ PM2 Logs    │               │
│  │ agent.log   │                │ combined.log│               │
│  │             │                │ error.log   │               │
│  └─────────────┘                └─────────────┘               │
│       │                                  │                    │
│       ▼                                  ▼                    │
│  ┌─────────────┐                ┌─────────────┐               │
│  │ SystemD     │                │ SystemD     │               │
│  │ Journal     │                │ Journal     │               │
│  │ (journalctl)│                │ (journalctl)│               │
│  └─────────────┘                └─────────────┘               │
│       │                                  │                    │
│       └─────────────┬────────────────────┘                    │
│                     ▼                                         │
│  ┌─────────────────────────────┐                              │
│  │    Centralized Logging      │                              │
│  │   (Optional: ELK Stack,     │                              │
│  │    Grafana Loki, etc.)      │                              │
│  └─────────────────────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

### Metrics Collection

Both services provide metrics through:
- **Health endpoints** returning JSON status
- **System metrics** via standard Linux tools
- **Application metrics** through log analysis
- **Resource usage** via Proxmox VE monitoring

## 🚀 Scaling Patterns

### Horizontal Scaling

```
Single Instance:
┌─────────────────┐
│ NetBox Agent    │
│ Container-140   │
└─────────────────┘

Multiple Instances:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ NetBox Agent    │  │ NetBox Agent    │  │ NetBox Agent    │
│ Container-140   │  │ Container-141   │  │ Container-142   │
│ Network-A       │  │ Network-B       │  │ Network-C       │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

Each container can be configured for different:
- **Network segments** for distributed scanning
- **Data sources** for specialized discovery
- **Sync intervals** for different update frequencies
- **Geographic locations** for multi-site deployments

### Load Distribution

```
┌─────────────────────────────────────────────────────────────────┐
│                    Load Balancer                               │
│                  (nginx/HAProxy)                               │
├─────────────────────────────────────────────────────────────────┤
│                         │                                       │
│    ┌────────────────────┼────────────────────┐                 │
│    │                    │                    │                 │
│    ▼                    ▼                    ▼                 │
│ ┌─────────┐         ┌─────────┐         ┌─────────┐            │
│ │WikiJS   │         │WikiJS   │         │WikiJS   │            │
│ │Intgr-130│         │Intgr-131│         │Intgr-132│            │
│ └─────────┘         └─────────┘         └─────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Backup & Recovery

### Data Persistence Strategy

**NetBox Agent**:
- **Configuration**: `/opt/netbox-agent/config/` - Contains JSON config and tokens
- **Logs**: `/opt/netbox-agent/logs/` - Application and rotation logs  
- **Code**: `/opt/netbox-agent/` - Git repository (can be re-cloned)

**WikiJS Integration**:
- **Configuration**: `/opt/wikijs-integration/production.env` - Environment variables
- **Database**: `/opt/wikijs-integration/wiki-agent.db` - SQLite database
- **Logs**: `/var/log/wikijs-integration/` - PM2 and application logs
- **Code**: `/opt/wikijs-integration/` - Node.js application

### Backup Procedures

```bash
# Proxmox VE container backup
vzdump <container-id>

# Application-specific backup
pct exec <container-id> -- tar -czf /backup/app-config.tar.gz \
  /opt/netbox-agent/config/ \
  /opt/wikijs-integration/production.env \
  /opt/wikijs-integration/wiki-agent.db
```

## 🔗 External Integrations

### Supported Integration Points

| Integration | NetBox Agent | WikiJS Integration | Protocol | Purpose |
|-------------|--------------|-------------------|----------|---------|
| **NetBox** | ✅ Primary | ❌ | REST API | IPAM/DCIM management |
| **WikiJS** | ❌ | ✅ Primary | GraphQL | Documentation management |
| **Home Assistant** | ✅ | ❌ | REST API | IoT device discovery |
| **Proxmox VE** | ✅ | ❌ | REST API | VM/Container inventory |
| **TrueNAS** | ✅ | ❌ | REST API | Storage system monitoring |
| **Git Repositories** | ❌ | ✅ | HTTPS/SSH | Source code integration |
| **Webhooks** | ❌ | ✅ | HTTP | Event-driven updates |

### Integration Deployment Example

```yaml
# Full homelab integration stack
services:
  - name: "NetBox"
    ip: "192.168.1.90"
    purpose: "IPAM/DCIM"
    
  - name: "WikiJS" 
    ip: "192.168.1.90"
    port: "3000"
    purpose: "Documentation"
    
  - name: "Home Assistant"
    ip: "192.168.1.10"
    port: "8123"
    purpose: "IoT Management"
    
  - name: "GitOps Auditor"
    ip: "192.168.1.58"
    purpose: "Repository monitoring"
    
  - name: "NetBox Agent"
    ip: "Dynamic DHCP"
    container_id: "140+"
    purpose: "Infrastructure discovery"
    
  - name: "WikiJS Integration"
    ip: "Dynamic DHCP" 
    container_id: "130+"
    purpose: "Documentation sync"
```

## 🎯 Future Architecture Considerations

### Planned Enhancements

1. **Microservices Architecture**: Breaking services into smaller, specialized components
2. **Container Orchestration**: Kubernetes or Docker Swarm integration
3. **Service Mesh**: Istio or Linkerd for advanced networking
4. **Event-Driven Architecture**: Message queues for asynchronous processing
5. **Multi-Tenancy**: Support for multiple homelab environments
6. **High Availability**: Clustering and failover capabilities

### Scalability Roadmap

```
Current: Single-Host Deployment
    ↓
Next: Multi-Host Clustering
    ↓
Future: Cloud-Native Architecture
    ↓
Vision: Hybrid Cloud Integration
```

This architecture provides a solid foundation for homelab automation while maintaining simplicity and reliability. The modular design allows for gradual expansion and integration with additional services as homelab requirements evolve.

## 📚 Related Documentation

- **[Home](Home)** - Project overview and navigation
- **[NetBox Agent Deployment](NetBox-Agent-Deployment)** - Detailed deployment guide
- **[WikiJS Integration Deployment](WikiJS-Integration-Deployment)** - Integration setup
- **[Troubleshooting](Troubleshooting)** - Common issues and solutions

For implementation details and specific configuration examples, refer to the individual deployment guides and troubleshooting documentation.