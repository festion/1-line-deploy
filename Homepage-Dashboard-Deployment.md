# Homepage Dashboard Deployment Guide

Complete guide for deploying the Homepage dashboard in an LXC container on Proxmox VE.

## Overview

Homepage is a modern, fully-featured application dashboard and launcher with integrations for over 100 services. It provides a beautiful, customizable interface to access all your homelab services.

## Features

- **Modern UI**: Beautiful dark/light theme support with customizable colors
- **Service Integration**: Built-in widgets for Docker, Proxmox, Uptime Kuma, and many more
- **Resource Monitoring**: Real-time monitoring of CPU, memory, and disk usage
- **Weather & Calendar**: Integrated widgets for daily information
- **Bookmarks & Search**: Quick access to frequently used services
- **Authentication Ready**: Works with reverse proxy authentication (Traefik, Authelia, etc.)
- **YAML Configuration**: Simple, GitOps-friendly configuration

## One-Line Deployment

Deploy Homepage to a Proxmox LXC container with a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/homepage.sh)"
```

## What Gets Deployed

### Container Specifications
- **OS**: Debian 12 (latest stable)
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disk**: 8GB
- **Network**: DHCP (auto-assigned IP)
- **Container ID**: Auto-numbered (150+)

### Software Stack
- **Node.js**: Version 20.x (LTS)
- **Package Manager**: pnpm (faster than npm)
- **Process Management**: systemd service
- **Homepage**: Latest version from GitHub

### Directory Structure
```
/home/homepage/
├── homepage/               # Main application directory
│   ├── config/            # Configuration files
│   │   ├── settings.yaml  # Dashboard settings
│   │   ├── services.yaml  # Service definitions
│   │   └── widgets.yaml   # Widget configuration
│   ├── public/            # Static assets
│   └── src/               # Source code
```

## Configuration

### Settings (settings.yaml)

Controls the overall appearance and behavior:

```yaml
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
```

**Available Options:**
- `theme`: dark, light
- `color`: slate, gray, zinc, neutral, stone, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose
- `headerStyle`: clean, boxed, underlined
- `target`: _blank (new tab), _self (same tab)

### Services (services.yaml)

Define your homelab services and their links:

```yaml
---
- Proxmox:
    - Proxmox VE:
        icon: proxmox.png
        href: https://proxmox.example.com:8006
        description: Virtualization Platform
        widget:
          type: proxmox
          url: https://proxmox.example.com:8006
          username: api@pam!homepage
          password: your-api-token

- Monitoring:
    - Uptime Kuma:
        icon: uptime-kuma.png
        href: https://uptime.example.com
        description: Service Monitoring
        widget:
          type: uptimekuma
          url: https://uptime.example.com
          slug: status-page-slug

- Network:
    - Traefik:
        icon: traefik.png
        href: https://traefik.example.com
        description: Reverse Proxy
        widget:
          type: traefik
          url: https://traefik.example.com
```

### Widgets (widgets.yaml)

Add informational widgets to your dashboard:

```yaml
---
- search:
    provider: google
    target: _blank

- datetime:
    text_size: xl
    format:
      dateStyle: long
      timeStyle: short

- openmeteo:
    label: Home
    latitude: 40.7128
    longitude: -74.0060
    units: metric
    cache: 5
```

## Supported Integrations

### Infrastructure
- **Proxmox VE**: VM/container stats, resource usage
- **Docker**: Container status and stats
- **Portainer**: Container management
- **TrueNAS**: Storage statistics

### Monitoring
- **Uptime Kuma**: Service monitoring status
- **Prometheus**: Metrics visualization
- **Grafana**: Dashboard links
- **Healthchecks**: Service health monitoring

### Media
- **Plex**: Media server stats
- **Jellyfin**: Media server stats
- **Sonarr/Radarr**: Download statistics
- **Tautulli**: Plex statistics

### Network
- **Traefik**: Reverse proxy stats
- **Pi-hole**: DNS blocking statistics
- **AdGuard Home**: DNS statistics
- **UniFi**: Network statistics

[Full list of 100+ integrations](https://gethomepage.dev/latest/widgets/)

## Traefik Integration

### Static IP Configuration (Optional)

If you want a static IP for easier Traefik configuration:

```bash
pct enter <container-id>

# Edit network configuration
nano /etc/network/interfaces
```

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.XXX/24
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1
```

```bash
systemctl restart networking
```

### Traefik File Provider Configuration

Create a dynamic configuration file for Traefik:

```yaml
# traefik/dynamic/homepage.yml
http:
  routers:
    homepage:
      rule: "Host(`home.yourdomain.com`)"
      entryPoints:
        - websecure
      service: homepage
      tls:
        certResolver: letsencrypt
      middlewares:
        - auth  # Optional: Add authentication

  services:
    homepage:
      loadBalancer:
        servers:
          - url: "http://192.168.1.XXX:3000"  # Your Homepage LXC IP
```

### With Authentication (Authelia/Authentik)

```yaml
http:
  routers:
    homepage:
      rule: "Host(`home.yourdomain.com`)"
      entryPoints:
        - websecure
      service: homepage
      tls:
        certResolver: letsencrypt
      middlewares:
        - authelia  # or authentik

  middlewares:
    authelia:
      forwardAuth:
        address: "http://authelia:9091/api/verify?rd=https://auth.yourdomain.com"
        trustForwardHeader: true
        authResponseHeaders:
          - "Remote-User"
          - "Remote-Groups"
```

## Advanced Configuration

### Proxmox Integration

To display Proxmox VM/container stats, you need an API token:

1. **Create API Token in Proxmox:**
   ```bash
   # On Proxmox host
   pveum user add homepage@pam
   pveum acl modify / -user homepage@pam -role PVEAuditor
   pveum user token add homepage@pam homepage -privsep 0
   ```

2. **Add to services.yaml:**
   ```yaml
   - Proxmox:
       - Node:
           widget:
             type: proxmox
             url: https://192.168.1.1:8006
             username: homepage@pam!homepage
             password: your-api-token-here
             node: pve
   ```

### Docker Integration

To show Docker container stats, mount the Docker socket:

```bash
# On Proxmox host
pct set <container-id> -mp0 /var/run/docker.sock:/var/run/docker.sock,mp=/var/run/docker.sock
```

Then configure in services.yaml:

```yaml
- Docker:
    - Container Server:
        widget:
          type: docker
          url: unix:///var/run/docker.sock
```

### Resource Monitoring

Display system resources on the dashboard:

```yaml
# In widgets.yaml
- resources:
    cpu: true
    memory: true
    disk: /
    expanded: true
    label: Homepage Server
```

## Management Commands

### View Logs
```bash
pct exec <container-id> -- journalctl -u homepage -f
```

### Restart Service
```bash
pct exec <container-id> -- systemctl restart homepage
```

### Check Service Status
```bash
pct exec <container-id> -- systemctl status homepage
```

### Update Homepage
```bash
# Re-run the deployment script - it will detect existing container
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/homepage.sh)"
# Select option 1 to update
```

### Manual Update
```bash
pct enter <container-id>
su - homepage
cd homepage
git pull
pnpm install
pnpm build
exit
systemctl restart homepage
```

### Edit Configuration
```bash
pct exec <container-id> -- nano /home/homepage/homepage/config/services.yaml
pct exec <container-id> -- nano /home/homepage/homepage/config/settings.yaml
pct exec <container-id> -- systemctl restart homepage  # Apply changes
```

## Backup and Restore

### Backup Configuration
```bash
# On Proxmox host
pct exec <container-id> -- tar -czf /tmp/homepage-config.tar.gz -C /home/homepage/homepage config
pct pull <container-id> /tmp/homepage-config.tar.gz ./homepage-config.tar.gz
```

### Restore Configuration
```bash
# On Proxmox host
pct push <container-id> ./homepage-config.tar.gz /tmp/homepage-config.tar.gz
pct exec <container-id> -- tar -xzf /tmp/homepage-config.tar.gz -C /home/homepage/homepage
pct exec <container-id> -- chown -R homepage:homepage /home/homepage/homepage/config
pct exec <container-id> -- systemctl restart homepage
```

### Full Container Backup
```bash
# Using Proxmox built-in backup
vzdump <container-id> --mode stop --storage local
```

## Troubleshooting

### Service Won't Start

Check logs:
```bash
pct exec <container-id> -- journalctl -u homepage -n 50
```

Check if port is in use:
```bash
pct exec <container-id> -- netstat -tlnp | grep 3000
```

### Configuration Errors

Validate YAML syntax:
```bash
pct exec <container-id> -- su - homepage -c 'cd homepage && pnpm validate'
```

### Permission Issues

Fix ownership:
```bash
pct exec <container-id> -- chown -R homepage:homepage /home/homepage/homepage
```

### Can't Access Dashboard

Check if service is running:
```bash
pct exec <container-id> -- systemctl status homepage
```

Check firewall (if enabled):
```bash
pct exec <container-id> -- iptables -L -n
```

Test locally:
```bash
pct exec <container-id> -- curl -I http://localhost:3000
```

## Security Considerations

### Authentication

Homepage itself doesn't have built-in authentication. Use one of these methods:

1. **Reverse Proxy Authentication** (Recommended)
   - Traefik + BasicAuth
   - Traefik + Authelia
   - Traefik + Authentik
   - Nginx Proxy Manager with access lists

2. **Network Isolation**
   - Keep on internal network only
   - VPN access required (WireGuard, Tailscale)

3. **Cloudflare Access**
   - Use Cloudflare Zero Trust
   - Supports passkeys/WebAuthn

### API Tokens

- Store Proxmox/Docker API tokens in configuration files
- Ensure config files have proper permissions (600)
- Use read-only tokens when possible
- Rotate tokens periodically

### SSL/TLS

- Always use HTTPS via reverse proxy
- Use Let's Encrypt for certificates
- Enable HSTS headers in Traefik/Nginx

## Performance Tuning

### Reduce Memory Usage

```bash
# Edit systemd service
pct exec <container-id> -- nano /etc/systemd/system/homepage.service
```

Add memory limit:
```ini
[Service]
Environment=NODE_OPTIONS=--max-old-space-size=512
```

### Cache Settings

Configure widget cache times in config:
```yaml
- widget:
    type: proxmox
    cache: 5  # Cache for 5 minutes
```

## GitOps Integration

### Version Control Configuration

```bash
# On your workstation
git clone https://github.com/yourusername/homelab-config
cd homelab-config
mkdir -p homepage/config

# Copy config from container
scp root@proxmox:/path/to/config/* homepage/config/

# Commit and push
git add homepage/
git commit -m "Add Homepage configuration"
git push
```

### Automated Deployment

Create a sync script:
```bash
#!/bin/bash
# sync-homepage-config.sh

CONTAINER_ID=150
CONFIG_PATH="/home/homepage/homepage/config"

# Pull latest from git
git pull

# Push to container
pct push $CONTAINER_ID ./homepage/config/settings.yaml $CONFIG_PATH/settings.yaml
pct push $CONTAINER_ID ./homepage/config/services.yaml $CONFIG_PATH/services.yaml
pct push $CONTAINER_ID ./homepage/config/widgets.yaml $CONFIG_PATH/widgets.yaml

# Restart service
pct exec $CONTAINER_ID -- systemctl restart homepage
```

## Resources

- **Official Documentation**: https://gethomepage.dev/latest/
- **GitHub Repository**: https://github.com/gethomepage/homepage
- **Widget Documentation**: https://gethomepage.dev/latest/widgets/
- **Service Icons**: https://gethomepage.dev/latest/configs/service-widgets/#icons
- **Community Examples**: https://github.com/gethomepage/homepage/discussions

## Support

For issues with the deployment script:
- GitHub Issues: https://github.com/festion/1-line-deploy/issues

For Homepage application issues:
- Homepage GitHub: https://github.com/gethomepage/homepage/issues
- Homepage Discord: https://discord.gg/k4ruYNrudu
