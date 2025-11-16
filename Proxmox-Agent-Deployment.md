# Proxmox Agent Dashboard Deployment

One-line deployment script for Proxmox cluster monitoring dashboard.

## Quick Deploy

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/proxmox-agent.sh)"
```

## Features

### Smart Deployment
- **Automatic Container Detection** - Finds existing Proxmox Agent containers
- **Update/Create Modes** - Update existing installations or create new containers
- **Auto ID Assignment** - Finds available container IDs (150-200 range)
- **Production Ready** - Complete with systemd services and monitoring

### Monitoring Capabilities
- **Real-time Cluster Monitoring** - WebSocket-based live updates
- **Multi-Node Support** - Monitors 3-node cluster (proxmox, proxmox2, proxmox3)
- **Alert Management** - View, acknowledge, and manage cluster alerts
- **Resource Tracking** - CPU, memory, disk, load averages per node
- **Automated Remediation** - Intelligent load balancing and optimization
- **High Availability** - Quorum monitoring and failover support

### Technical Stack
- **Backend:** Python 3.11+ with FastAPI and async Proxmox API
- **Frontend:** React + Vite with modern UI components
- **Services:** Supervisor for backend, Nginx for frontend
- **Monitoring:** Real-time WebSocket connections
- **API:** RESTful API with OpenAPI documentation

## Container Specifications

| Specification | Value |
|--------------|-------|
| **Container ID** | Auto-assigned (150+) |
| **Hostname** | proxmox-agent |
| **CPU** | 2 cores |
| **RAM** | 2GB |
| **Disk** | 8GB |
| **Network** | DHCP (vmbr0) |
| **OS** | Debian 12 LXC |
| **Start on Boot** | Yes |
| **Unprivileged** | Yes |

## Cluster Configuration

The dashboard monitors a 3-node Proxmox cluster:

| Node | IP | Hardware | Role | Priority |
|------|-----|----------|------|----------|
| proxmox | 192.168.1.137 | Intel N100, 4c/4t | Primary | High |
| proxmox2 | 192.168.1.125 | Intel i7-6700, 4c/8t | Worker | Medium |
| proxmox3 | 192.168.1.126 | Intel i7-6700, 4c/8t | Worker | Medium |

## Service Endpoints

After deployment, the following endpoints are available:

- **Dashboard:** `http://<container-ip>`
- **API Documentation:** `http://<container-ip>/docs`
- **Health Check:** `http://<container-ip>/api/health`
- **Cluster Status:** `http://<container-ip>/api/cluster/status`

## Default Credentials

**Username:** `admin`
**Password:** `proxmox123`

⚠️ **Security Note:** Change these credentials in `/opt/proxmox-agent/.env` after deployment!

## Deployment Process

The deployment script performs the following steps:

1. **Proxmox Version Check** - Ensures PVE 8.0+
2. **Container Detection** - Checks for existing installations
3. **Template Download** - Downloads Debian 12 template if needed
4. **Container Creation** - Creates LXC container with specified resources
5. **System Setup** - Installs Node.js 20, Python 3.11, Nginx, Supervisor
6. **Repository Clone** - Clones proxmox-agent from GitHub
7. **Dependencies** - Installs Python and Node.js dependencies
8. **Frontend Build** - Builds production React application
9. **Service Configuration** - Sets up Supervisor and Nginx
10. **Service Start** - Starts backend API and frontend

## Installation Steps

### Fresh Installation

1. Run the one-line deployment command on your Proxmox host
2. Wait for container creation and software installation (5-10 minutes)
3. Note the container IP address from the completion message
4. Access the dashboard at `http://<container-ip>`
5. Login with default credentials

### Update Existing Installation

1. Run the same one-line deployment command
2. Select option 1 to update existing container
3. Wait for repository update and rebuild
4. Services automatically restart with new code

## Post-Deployment Configuration

### 1. Update Credentials

```bash
pct exec <container-id> -- nano /opt/proxmox-agent/.env
```

Edit the following:
```env
API_USERNAME=your_username
API_PASSWORD=your_secure_password
```

Restart backend:
```bash
pct exec <container-id> -- supervisorctl restart proxmox-agent-backend
```

### 2. Configure Proxmox Access

Ensure SSH access to all cluster nodes:
```bash
ssh-copy-id root@192.168.1.137  # proxmox
ssh-copy-id root@192.168.1.125  # proxmox2
ssh-copy-id root@192.168.1.126  # proxmox3
```

### 3. Set Up Traefik Reverse Proxy

Create Traefik configuration at `/etc/traefik/dynamic/proxmox-agent.yml`:

```yaml
http:
  routers:
    proxmox-agent:
      rule: "Host(`proxmox-agent.internal.lakehouse.wtf`)"
      service: proxmox-agent
      entryPoints:
        - websecure
      tls:
        certResolver: cloudflare
      middlewares:
        - default-headers

  services:
    proxmox-agent:
      loadBalancer:
        servers:
          - url: "http://<container-ip>:80"
```

### 4. Create DHCP Reservation

Add static DHCP reservation for the container to maintain consistent IP.

### 5. Add to Monitoring

**Uptime Kuma:**
- Add HTTP monitor for `https://proxmox-agent.internal.lakehouse.wtf`
- Set check interval to 60 seconds

**Homepage Dashboard:**
Add service entry to `config/services.yaml`:

```yaml
- Proxmox:
    - Proxmox Agent Dashboard:
        icon: proxmox.png
        href: https://proxmox-agent.internal.lakehouse.wtf
        description: Cluster monitoring and management
        widget:
          type: customapi
          url: https://proxmox-agent.internal.lakehouse.wtf/api/cluster/status
```

## Monitoring Features

### Cluster Status Dashboard
- **Nodes Online/Offline** - Real-time node availability
- **Quorum Status** - Cluster quorum health
- **Resource Usage** - CPU, memory, disk per node
- **Load Averages** - 1m, 5m, 15m load metrics

### Alert System
- **Warning Thresholds** - Load > 75% of cores
- **Critical Thresholds** - Load > 90% of cores
- **Automated Actions** - Optimize kernel parameters, apply CPU limits
- **Alert History** - Track all alerts and remediation actions

### Remediation Capabilities
- **Kernel Optimization** - IO scheduler adjustments
- **CPU Limiting** - Apply limits to high-CPU containers
- **Service Suspension** - Pause non-critical workloads
- **Load Balancing** - Recommendations for VM/container migration

## Management Commands

### View Logs
```bash
# Backend logs
pct exec <container-id> -- tail -f /var/log/proxmox-agent-backend.log

# Nginx logs
pct exec <container-id> -- tail -f /var/log/nginx/access.log
pct exec <container-id> -- tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
# Restart backend
pct exec <container-id> -- supervisorctl restart proxmox-agent-backend

# Restart nginx
pct exec <container-id> -- systemctl restart nginx

# Restart both
pct exec <container-id> -- bash -c "supervisorctl restart proxmox-agent-backend && systemctl restart nginx"
```

### Update Dashboard
```bash
# SSH into container
pct enter <container-id>

# Update repository
cd /opt/proxmox-agent
git pull

# Rebuild frontend
cd dashboard/frontend
npm install
npm run build

# Restart services
supervisorctl restart proxmox-agent-backend
systemctl reload nginx
```

### Check Service Status
```bash
# Supervisor status
pct exec <container-id> -- supervisorctl status

# Nginx status
pct exec <container-id> -- systemctl status nginx

# Check if services are responding
curl http://<container-ip>/api/health
```

## Troubleshooting

### Backend Not Starting

**Check logs:**
```bash
pct exec <container-id> -- tail -50 /var/log/proxmox-agent-backend.log
```

**Common issues:**
- Missing Python dependencies → Reinstall requirements
- Port 8000 already in use → Check for conflicting services
- SSH access issues → Verify SSH keys to Proxmox nodes

### Frontend Not Loading

**Check Nginx:**
```bash
pct exec <container-id> -- nginx -t
pct exec <container-id> -- systemctl status nginx
```

**Common issues:**
- Build files missing → Rebuild frontend
- Nginx misconfiguration → Check `/etc/nginx/sites-available/proxmox-agent`
- Port 80 conflict → Check for other services

### Cluster Nodes Not Responding

**Verify SSH access:**
```bash
ssh root@192.168.1.137 "pvecm status"
ssh root@192.168.1.125 "pvecm status"
ssh root@192.168.1.126 "pvecm status"
```

**Check firewall:**
Ensure SSH port 22 is open between container and Proxmox nodes.

### WebSocket Connection Failed

**Check backend logs:**
```bash
pct exec <container-id> -- tail -f /var/log/proxmox-agent-backend.log | grep -i websocket
```

**Common issues:**
- Reverse proxy configuration → Verify WebSocket support in Traefik/NPM
- Backend not running → Restart supervisor service
- CORS issues → Check API middleware configuration

## File Locations

### Application Files
- **Repository:** `/opt/proxmox-agent`
- **Backend:** `/opt/proxmox-agent/dashboard/backend`
- **Frontend:** `/opt/proxmox-agent/dashboard/frontend`
- **Environment:** `/opt/proxmox-agent/.env`

### Configuration Files
- **Supervisor:** `/etc/supervisor/conf.d/proxmox-agent-backend.conf`
- **Nginx:** `/etc/nginx/sites-available/proxmox-agent`
- **Cluster Config:** `/opt/proxmox-agent/config/cluster.yaml`

### Log Files
- **Backend:** `/var/log/proxmox-agent-backend.log`
- **Nginx Access:** `/var/log/nginx/access.log`
- **Nginx Error:** `/var/log/nginx/error.log`
- **Supervisor:** `/var/log/supervisor/supervisord.log`

## Security Considerations

### Authentication
- Change default credentials immediately
- Use strong passwords (12+ characters, mixed case, numbers, symbols)
- Consider implementing JWT tokens for API access

### Network Security
- Use Traefik reverse proxy for SSL/TLS
- Implement firewall rules to restrict access
- Use VPN or Tailscale for remote access
- Enable fail2ban for SSH protection

### SSH Access
- Use SSH keys instead of passwords
- Restrict SSH access to specific IPs
- Disable root SSH login (use sudo)
- Regular security updates

### Container Security
- Run unprivileged containers
- Apply Proxmox security updates
- Monitor logs for suspicious activity
- Use AppArmor/SELinux profiles

## Performance Optimization

### Resource Allocation
- Increase RAM to 4GB for larger clusters (10+ nodes)
- Add more CPU cores if monitoring >5 nodes
- Use SSD storage for better I/O performance

### Backend Optimization
- Adjust polling intervals in configuration
- Use caching for frequently accessed data
- Optimize database queries (if using database)

### Frontend Optimization
- Enable nginx gzip compression
- Use CDN for static assets
- Implement service worker caching
- Optimize React bundle size

## Future Enhancements

- [ ] Prometheus metrics export
- [ ] Grafana dashboard templates
- [ ] Automated VM/container migration
- [ ] Predictive load forecasting
- [ ] Email/SMS alerting
- [ ] Slack/Discord webhook integration
- [ ] Backup automation and verification
- [ ] Multi-cluster support

## Documentation Links

- **Project Repository:** https://github.com/festion/proxmox-agent
- **Quick Start Guide:** https://github.com/festion/proxmox-agent/blob/main/QUICKSTART.md
- **Dashboard README:** https://github.com/festion/proxmox-agent/blob/main/dashboard/DASHBOARD_README.md
- **Full Documentation:** https://github.com/festion/proxmox-agent/blob/main/README.md

## Support

For issues, questions, or contributions:
- **GitHub Issues:** https://github.com/festion/proxmox-agent/issues
- **1-Line Deploy Issues:** https://github.com/festion/1-line-deploy/issues

## License

MIT License - See LICENSE file for details
