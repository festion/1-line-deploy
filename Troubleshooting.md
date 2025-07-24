# Troubleshooting Guide

This comprehensive troubleshooting guide covers common issues, solutions, and frequently asked questions for the 1-Line Deploy project deployments. Use this guide to diagnose and resolve problems with NetBox Agent and WikiJS Integration containers.

## 🚨 Quick Diagnostics

### Container Status Check
```bash
# List all containers
pct list

# Check specific container status
pct status <container-id>

# View container configuration
pct config <container-id>

# Check container resource usage
pct exec <container-id> -- top
```

### Network Connectivity
```bash
# Check container IP address
pct exec <container-id> -- hostname -I

# Test external connectivity
pct exec <container-id> -- ping -c 3 8.8.8.8

# Test local network connectivity
pct exec <container-id> -- ping -c 3 192.168.1.1

# Check DNS resolution
pct exec <container-id> -- nslookup github.com
```

### Service Status Overview
```bash
# Check all systemd services
pct exec <container-id> -- systemctl --failed

# Check specific service
pct exec <container-id> -- systemctl status <service-name>

# View recent logs
pct exec <container-id> -- journalctl --since "1 hour ago"
```

## 🔧 Deployment Issues

### Container Creation Failures

**Problem**: Deployment script fails during container creation

**Common Causes**:
- Insufficient storage space
- Network connectivity issues
- Missing LXC templates
- Proxmox version incompatibility

**Solutions**:

1. **Check Available Storage**:
   ```bash
   # Check Proxmox storage
   pvesm status
   
   # Check specific storage
   pvesm status local-lvm
   ```

2. **Verify Proxmox Version**:
   ```bash
   pveversion
   # Should show 8.0 or later
   ```

3. **Download Missing Templates**:
   ```bash
   # List available templates
   pveam available
   
   # Download Debian 12 template
   pveam download local debian-12-standard_12.7-1_amd64.tar.zst
   ```

4. **Check Network Configuration**:
   ```bash
   # Verify bridge exists
   ip link show vmbr0
   
   # Check DHCP server availability
   nmap --script broadcast-dhcp-discover
   ```

### Container ID Conflicts

**Problem**: "Container ID already exists" error

**Solutions**:

1. **Check Existing Containers**:
   ```bash
   pct list | grep -E "(130|140|150|160|170|180|190|200)"
   ```

2. **Remove Unused Containers**:
   ```bash
   # Stop container
   pct stop <container-id>
   
   # Destroy container
   pct destroy <container-id>
   ```

3. **Manual ID Selection**:
   - The scripts automatically find available IDs
   - If issues persist, check the ID range 130-200 for availability

### Template Download Issues

**Problem**: Debian template download fails

**Solutions**:

1. **Check Internet Connectivity**:
   ```bash
   ping -c 3 download.proxmox.com
   ```

2. **Manual Template Download**:
   ```bash
   wget http://download.proxmox.com/images/system/debian-12-standard_12.7-1_amd64.tar.zst
   pveam upload local debian-12-standard_12.7-1_amd64.tar.zst
   ```

3. **Alternative Template Sources**:
   ```bash
   # Use different mirror
   pveam set-mirror http://download.proxmox.com/images
   pveam update
   ```

## 🐛 NetBox Agent Issues

### Service Won't Start

**Problem**: NetBox Agent service fails to start

**Diagnostic Steps**:
```bash
# Check service status
pct exec <container-id> -- systemctl status netbox-agent

# View detailed logs
pct exec <container-id> -- journalctl -u netbox-agent -f

# Check Python process
pct exec <container-id> -- ps aux | grep python
```

**Common Solutions**:

1. **Missing Dependencies**:
   ```bash
   # Reinstall Python dependencies
   pct exec <container-id> -- sudo -u netbox-agent bash -c "
   cd /opt/netbox-agent
   source venv/bin/activate
   pip install -r requirements.txt
   "
   ```

2. **Configuration Errors**:
   ```bash
   # Validate JSON configuration
   pct exec <container-id> -- python3 -m json.tool /opt/netbox-agent/config/netbox-agent.json
   
   # Check environment file
   pct exec <container-id> -- cat /opt/netbox-agent/.env
   ```

3. **Permission Issues**:
   ```bash
   # Fix file ownership
   pct exec <container-id> -- chown -R netbox-agent:netbox-agent /opt/netbox-agent
   
   # Fix permissions
   pct exec <container-id> -- chmod 600 /opt/netbox-agent/.env
   ```

### NetBox Connection Issues

**Problem**: Cannot connect to NetBox API

**Diagnostic Steps**:
```bash
# Test NetBox connectivity
pct exec <container-id> -- curl -I https://netbox.homelab.local

# Test API endpoint
pct exec <container-id> -- curl -H "Authorization: Token YOUR_TOKEN" https://netbox.homelab.local/api/

# Check DNS resolution
pct exec <container-id> -- nslookup netbox.homelab.local
```

**Solutions**:

1. **Verify NetBox URL and Token**:
   ```bash
   # Edit configuration
   pct exec <container-id> -- nano /opt/netbox-agent/config/netbox-agent.json
   
   # Update these fields:
   # "url": "https://netbox.homelab.local"
   # "token": "your-valid-api-token"
   ```

2. **SSL Certificate Issues**:
   ```bash
   # Disable SSL verification temporarily
   # In netbox-agent.json:
   # "verify_ssl": false
   ```

3. **Network Routing Issues**:
   ```bash
   # Check routing table
   pct exec <container-id> -- ip route
   
   # Test specific route
   pct exec <container-id> -- traceroute netbox.homelab.local
   ```

### Discovery Not Working

**Problem**: No devices being discovered or synchronized

**Diagnostic Steps**:
```bash
# Check network scanning
pct exec <container-id> -- sudo -u netbox-agent nmap -sn 192.168.1.0/24

# Test Home Assistant connection
pct exec <container-id> -- curl -H "Authorization: Bearer YOUR_HA_TOKEN" http://192.168.1.10:8123/api/

# Check log files
pct exec <container-id> -- tail -f /opt/netbox-agent/logs/netbox-agent.log
```

**Solutions**:

1. **Enable Discovery Sources**:
   ```json
   {
     "sources": {
       "network_scan": {
         "enabled": true,
         "networks": ["192.168.1.0/24"]
       }
     }
   }
   ```

2. **Check Network Permissions**:
   ```bash
   # NetBox Agent needs network access
   # Verify container can reach target networks
   pct exec <container-id> -- ping 192.168.1.1
   ```

3. **Home Assistant Token Issues**:
   ```bash
   # Create and store HA token
   echo "your_ha_token" > /opt/netbox-agent/config/ha_token
   chmod 600 /opt/netbox-agent/config/ha_token
   chown netbox-agent:netbox-agent /opt/netbox-agent/config/ha_token
   ```

## 🌐 WikiJS Integration Issues

### Service Won't Start

**Problem**: WikiJS Integration service fails to start

**Diagnostic Steps**:
```bash
# Check systemd service
pct exec <container-id> -- systemctl status wikijs-integration

# Check PM2 status
pct exec <container-id> -- sudo -u wikijs-integration pm2 status

# View PM2 logs
pct exec <container-id> -- sudo -u wikijs-integration pm2 logs wikijs-integration
```

**Common Solutions**:

1. **Node.js Issues**:
   ```bash
   # Check Node.js version
   pct exec <container-id> -- node --version
   # Should be v20.x
   
   # Reinstall dependencies
   pct exec <container-id> -- sudo -u wikijs-integration bash -c "
   cd /opt/wikijs-integration
   npm install
   "
   ```

2. **PM2 Process Issues**:
   ```bash
   # Stop all PM2 processes
   pct exec <container-id> -- sudo -u wikijs-integration pm2 kill
   
   # Start with ecosystem file
   pct exec <container-id> -- sudo -u wikijs-integration pm2 start /opt/wikijs-integration/ecosystem.config.js
   
   # Save PM2 configuration
   pct exec <container-id> -- sudo -u wikijs-integration pm2 save
   ```

3. **Port Conflicts**:
   ```bash
   # Check if port 3001 is in use
   pct exec <container-id> -- netstat -tlnp | grep :3001
   
   # Kill conflicting process
   pct exec <container-id> -- kill <pid>
   ```

### WikiJS Connection Issues

**Problem**: Cannot connect to WikiJS API

**Diagnostic Steps**:
```bash
# Test WikiJS connectivity
pct exec <container-id> -- curl -I http://192.168.1.90:3000

# Test GraphQL endpoint
pct exec <container-id> -- curl -X POST \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  http://192.168.1.90:3000/graphql \
  -d '{"query":"{ pages { list { id title } } }"}'
```

**Solutions**:

1. **Invalid JWT Token**:
   ```bash
   # Generate new token in WikiJS
   # Navigate to: http://192.168.1.90:3000/a
   # Administration → API → Create new key
   
   # Update environment file
   pct exec <container-id> -- nano /opt/wikijs-integration/production.env
   # WIKIJS_TOKEN=your-new-jwt-token
   ```

2. **WikiJS Service Down**:
   ```bash
   # Check WikiJS container status
   pct status <wikijs-container-id>
   
   # Start WikiJS if stopped
   pct start <wikijs-container-id>
   ```

3. **Network Routing**:
   ```bash
   # Check network connectivity
   pct exec <container-id> -- ping 192.168.1.90
   
   # Verify routing
   pct exec <container-id> -- traceroute 192.168.1.90
   ```

### Database Issues

**Problem**: SQLite database errors

**Solutions**:

1. **Database Corruption**:
   ```bash
   # Check database integrity
   pct exec <container-id> -- sudo -u wikijs-integration sqlite3 /opt/wikijs-integration/wiki-agent.db "PRAGMA integrity_check;"
   
   # Recreate database if corrupted
   pct exec <container-id> -- sudo -u wikijs-integration rm /opt/wikijs-integration/wiki-agent.db
   pct exec <container-id> -- sudo -u wikijs-integration sqlite3 /opt/wikijs-integration/wiki-agent.db "PRAGMA user_version = 1;"
   ```

2. **Permission Issues**:
   ```bash
   # Fix database permissions
   pct exec <container-id> -- chown wikijs-integration:wikijs-integration /opt/wikijs-integration/wiki-agent.db
   pct exec <container-id> -- chmod 644 /opt/wikijs-integration/wiki-agent.db
   ```

## 🌐 Network and Connectivity Issues

### DHCP Assignment Problems

**Problem**: Container doesn't receive IP address

**Solutions**:

1. **Check DHCP Server**:
   ```bash
   # From Proxmox host
   nmap --script broadcast-dhcp-discover
   ```

2. **Manual IP Assignment**:
   ```bash
   # Stop container
   pct stop <container-id>
   
   # Set static IP
   pct set <container-id> --net0 name=eth0,bridge=vmbr0,ip=192.168.1.50/24,gw=192.168.1.1
   
   # Start container
   pct start <container-id>
   ```

3. **Network Bridge Issues**:
   ```bash
   # Check bridge status
   ip link show vmbr0
   
   # Verify bridge configuration
   cat /etc/network/interfaces | grep -A 10 vmbr0
   ```

### DNS Resolution Issues

**Problem**: Cannot resolve domain names

**Solutions**:

1. **Check DNS Configuration**:
   ```bash
   pct exec <container-id> -- cat /etc/resolv.conf
   ```

2. **Set Custom DNS**:
   ```bash
   # Edit container configuration
   pct set <container-id> --nameserver 8.8.8.8,1.1.1.1
   
   # Or manually in container
   pct exec <container-id> -- bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
   ```

### Firewall Issues

**Problem**: Services unreachable from network

**Solutions**:

1. **Check Proxmox Firewall**:
   ```bash
   # Check firewall status
   pve-firewall status
   
   # List firewall rules
   pve-firewall localnet
   ```

2. **Container Firewall**:
   ```bash
   # Check iptables in container
   pct exec <container-id> -- iptables -L
   
   # Check if ufw is active
   pct exec <container-id> -- ufw status
   ```

## 📊 Performance Issues

### High Memory Usage

**Problem**: Container using excessive memory

**Solutions**:

1. **Check Memory Usage**:
   ```bash
   # Container memory stats
   pct exec <container-id> -- free -h
   
   # Process memory usage
   pct exec <container-id> -- ps aux --sort=-%mem | head -10
   ```

2. **Adjust Memory Limits**:
   ```bash
   # Increase container memory
   pct set <container-id> --memory 2048
   
   # For PM2 processes (WikiJS Integration)
   pct exec <container-id> -- sudo -u wikijs-integration pm2 restart wikijs-integration --max-memory-restart 256M
   ```

### High CPU Usage

**Problem**: Container consuming excessive CPU

**Solutions**:

1. **Identify CPU-intensive Processes**:
   ```bash
   pct exec <container-id> -- top -c
   ```

2. **Adjust Sync Intervals**:
   ```bash
   # For NetBox Agent - increase sync intervals
   # Edit /opt/netbox-agent/config/netbox-agent.json
   "sync": {
     "full_sync_interval": 86400,
     "incremental_sync_interval": 7200
   }
   ```

## 🔐 Security Issues

### Certificate Problems

**Problem**: SSL/TLS certificate errors

**Solutions**:

1. **Update CA Certificates**:
   ```bash
   pct exec <container-id> -- apt-get update
   pct exec <container-id> -- apt-get install -y ca-certificates
   pct exec <container-id> -- update-ca-certificates
   ```

2. **Temporarily Disable SSL Verification**:
   ```bash
   # For testing only - in configuration files
   "verify_ssl": false
   ```

### Token Expiration

**Problem**: API tokens have expired

**Solutions**:

1. **NetBox Token Renewal**:
   - Generate new token in NetBox admin interface
   - Update `/opt/netbox-agent/config/netbox-agent.json`

2. **WikiJS Token Renewal**:
   - Generate new JWT token in WikiJS admin
   - Update `/opt/wikijs-integration/production.env`

## 📝 Log Analysis

### Important Log Locations

**NetBox Agent**:
```bash
# Service logs
journalctl -u netbox-agent -f

# Application logs
tail -f /opt/netbox-agent/logs/netbox-agent.log

# System logs
tail -f /var/log/syslog
```

**WikiJS Integration**:
```bash
# Systemd service logs
journalctl -u wikijs-integration -f

# PM2 logs
sudo -u wikijs-integration pm2 logs wikijs-integration

# Combined logs
tail -f /var/log/wikijs-integration/combined.log

# Error logs
tail -f /var/log/wikijs-integration/error.log
```

### Log Analysis Commands

```bash
# Search for errors
pct exec <container-id> -- grep -i error /var/log/syslog

# Find connection issues
pct exec <container-id> -- grep -i "connection" /opt/netbox-agent/logs/netbox-agent.log

# Monitor real-time logs
pct exec <container-id> -- tail -f /var/log/syslog | grep <container-name>
```

## ❓ Frequently Asked Questions

### Q: Can I run multiple instances of the same service?

**A**: Yes, the deployment scripts automatically find available container IDs. Each instance will have its own container ID and IP address.

### Q: How do I backup my containers?

**A**: Use Proxmox's built-in backup functionality:
```bash
# Create backup
vzdump <container-id>

# Restore from backup
pct restore <new-container-id> /var/lib/vz/dump/vzdump-lxc-<container-id>-*.tar.lz4
```

### Q: Can I change the container resources after deployment?

**A**: Yes, you can modify container resources:
```bash
# Change memory
pct set <container-id> --memory 2048

# Change CPU cores
pct set <container-id> --cores 4

# Changes require container restart
pct restart <container-id>
```

### Q: How do I update the services to the latest version?

**A**: Re-run the deployment script. It will detect existing containers and offer update options.

### Q: Can I customize the installation directory?

**A**: The scripts use standard directories (`/opt/netbox-agent`, `/opt/wikijs-integration`). Manual customization is possible but not recommended as it may break updates.

### Q: What if I need to change the container IP?

**A**: You can switch between DHCP and static IP:
```bash
# Switch to static IP
pct set <container-id> --net0 name=eth0,bridge=vmbr0,ip=192.168.1.100/24,gw=192.168.1.1

# Switch back to DHCP
pct set <container-id> --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

## 🆘 Getting Additional Help

If this troubleshooting guide doesn't resolve your issue:

1. **Check the specific deployment guides**:
   - [NetBox Agent Deployment](NetBox-Agent-Deployment)
   - [WikiJS Integration Deployment](WikiJS-Integration-Deployment)

2. **Review system architecture**:
   - [Architecture & Integration](Architecture-Integration)

3. **Report issues**:
   - [GitHub Issues](https://github.com/festion/1-line-deploy/issues)
   - Include container logs and error messages
   - Specify Proxmox version and container configuration

4. **Community support**:
   - Check existing GitHub issues for similar problems
   - Provide detailed error information when creating new issues

Remember to include relevant log output, container configuration, and system information when seeking help!