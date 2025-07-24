# WikiJS Integration Deployment

The WikiJS Integration container provides a production-ready Node.js service that bridges GitOps workflows with WikiJS document management. This service enables automated synchronization between Git repositories and WikiJS wiki pages, supporting comprehensive documentation workflows in homelab environments.

## 🎯 Overview

The WikiJS Integration service:

- **Synchronizes Git repositories** with WikiJS wiki pages
- **Provides GitOps workflows** for documentation management
- **Offers REST API endpoints** for integration with other services
- **Includes health monitoring** with built-in status checks
- **Supports PM2 process management** for production reliability

## 🚀 One-Line Deployment

Deploy the WikiJS Integration container with a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/wikijs-integration.sh)"
```

## 📋 Prerequisites

### System Requirements
- **Proxmox VE 8.0+** - Required for container management APIs
- **Available Resources**:
  - **CPU**: 2 cores minimum
  - **RAM**: 1GB minimum
  - **Disk**: 4GB available storage
  - **Network**: DHCP-enabled network segment

### External Dependencies
- **WikiJS Instance** - Running WikiJS installation (typically at 192.168.1.90:3000)
- **WikiJS API Token** - JWT token with appropriate permissions
- **Git Repository Access** - For syncing documentation content
- **Network Access** - Container must reach WikiJS and Git repositories

### Optional Integrations
- **GitOps Auditor** - For repository monitoring and sync coordination
- **GitHub/GitLab** - For webhook-based automatic synchronization
- **Nginx Proxy Manager** - For SSL termination and domain routing

## 🔧 Installation Process

### Automatic Container Detection

The deployment script automatically:

1. **Scans for existing containers** - Detects WikiJS Integration installations
2. **Offers update options** - Choose between update or new deployment
3. **Finds available container ID** - Auto-assigns ID in range 130-200
4. **Configures networking** - DHCP assignment with automatic detection

### Container Specifications

| Setting | Value | Description |
|---------|-------|-------------|
| **Container ID** | 130-200 | Auto-assigned from available range |
| **Hostname** | `wikijs-integration` | Default hostname (customizable) |
| **CPU Cores** | 2 | Dedicated CPU allocation |
| **RAM** | 1024 MB | Memory allocation |
| **Disk Space** | 4 GB | Root filesystem size |
| **Network** | DHCP | Automatic IP assignment |
| **OS** | Debian 12 | LXC container base |
| **Tags** | `gitops;integration;nodejs;wikijs;production` | Container metadata |

### Installation Steps

1. **Container Creation**
   - Downloads Debian 12 LXC template
   - Creates unprivileged container with specified resources
   - Configures network with DHCP

2. **System Setup**
   - Updates Debian packages
   - Installs Node.js 20 from NodeSource repository
   - Installs system dependencies (git, sqlite3, nginx)
   - Installs PM2 globally for process management

3. **WikiJS Integration Installation**
   - Creates dedicated `wikijs-integration` user
   - Sets up application directory structure
   - Creates package.json with production dependencies
   - Installs Node.js dependencies

4. **Service Configuration**
   - Creates PM2 ecosystem configuration
   - Sets up systemd service definitions
   - Configures nginx reverse proxy
   - Initializes SQLite database

## ⚙️ Configuration

### Application Structure

```
/opt/wikijs-integration/
├── api/
│   └── server-mcp.js          # Main application server
├── package.json               # Node.js dependencies
├── ecosystem.config.js        # PM2 configuration
├── production.env             # Environment variables
├── wiki-agent.db             # SQLite database
└── node_modules/             # Installed dependencies
```

### Primary Configuration

The main configuration is stored in `/opt/wikijs-integration/production.env`:

```bash
NODE_ENV=production
PORT=3001
WIKIJS_URL=http://192.168.1.90:3000
WIKIJS_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
DEBUG_WIKI_AGENT=true
```

### Package Dependencies

The service uses these key Node.js packages:

```json
{
  "dependencies": {
    "express": "^4.18.2",
    "sqlite3": "^5.1.6",
    "cors": "^2.8.5",
    "express-ws": "^5.0.2",
    "chokidar": "^3.5.3",
    "node-fetch": "^2.7.0"
  }
}
```

### PM2 Ecosystem Configuration

Process management is handled by PM2 with this configuration:

```javascript
module.exports = {
  apps: [{
    name: 'wikijs-integration',
    script: './api/server-mcp.js',
    cwd: '/opt/wikijs-integration',
    user: 'wikijs-integration',
    env_file: '/opt/wikijs-integration/production.env',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '512M',
    error_file: '/var/log/wikijs-integration/error.log',
    out_file: '/var/log/wikijs-integration/out.log',
    log_file: '/var/log/wikijs-integration/combined.log',
    time: true,
    restart_delay: 5000,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
```

## 🌐 Service Endpoints

After deployment, the WikiJS Integration service provides several HTTP endpoints:

### Health Check Endpoint
```bash
curl http://<container-ip>/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "wikijs-integration",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Service Status Endpoint
```bash
curl http://<container-ip>/wiki-agent/status
```

**Response:**
```json
{
  "status": "running",
  "version": "1.0.0",
  "environment": "production",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Main Service Endpoint
```bash
curl http://<container-ip>/
```

The main endpoint provides the core WikiJS integration functionality.

## 🚀 Getting Started

### 1. Deploy the Container

Run the one-line deployment command:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/wikijs-integration.sh)"
```

### 2. Obtain WikiJS API Token

Generate a JWT token in your WikiJS instance:

1. **Access WikiJS Admin Panel**:
   - Navigate to `http://192.168.1.90:3000/a`
   - Login with administrator credentials

2. **Create API Key**:
   - Go to Administration → API
   - Create new API key
   - Select appropriate permissions (read/write pages)
   - Copy the generated JWT token

3. **Verify Token Format**:
   ```
   eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGkiOjIsImdycCI6MSwiaWF0IjoxNzUwNjg5NzQ0...
   ```

### 3. Configure the Service

Update the environment configuration:

```bash
# Edit environment file
pct exec <container-id> -- nano /opt/wikijs-integration/production.env
```

**Required Settings:**
- `WIKIJS_URL` - Your WikiJS instance URL
- `WIKIJS_TOKEN` - JWT token from WikiJS API
- `PORT` - Service port (default: 3001)

### 4. Start the Service

The service should start automatically, but you can manage it manually:

```bash
# Check PM2 status
pct exec <container-id> -- sudo -u wikijs-integration pm2 status

# Restart service
pct exec <container-id> -- systemctl restart wikijs-integration

# Check systemd status
pct exec <container-id> -- systemctl status wikijs-integration
```

### 5. Verify Operation

```bash
# Test health endpoint
curl http://<container-ip>/health

# Check service logs
pct exec <container-id> -- journalctl -u wikijs-integration -f

# Monitor PM2 logs
pct exec <container-id> -- sudo -u wikijs-integration pm2 logs wikijs-integration
```

## 🔧 Advanced Configuration

### Custom WikiJS Integration

The default server provides basic endpoints, but you can extend functionality:

```javascript
// Example extension for custom endpoints
app.get('/api/sync', async (req, res) => {
  try {
    // Custom synchronization logic
    const result = await syncWithWikiJS();
    res.json({ status: 'success', result });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
});
```

### Database Customization

The service includes a SQLite database for local data storage:

```bash
# Access SQLite database
pct exec <container-id> -- sudo -u wikijs-integration sqlite3 /opt/wikijs-integration/wiki-agent.db

# Example table creation
CREATE TABLE sync_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT NOT NULL,
  status TEXT NOT NULL,
  details TEXT
);
```

### Webhook Integration

Set up webhooks for automatic synchronization:

```javascript
// Example webhook endpoint
app.post('/webhook/git', (req, res) => {
  const payload = req.body;
  
  if (payload.ref === 'refs/heads/main') {
    // Trigger synchronization on main branch updates
    triggerSync().catch(console.error);
  }
  
  res.json({ status: 'received' });
});
```

## 📊 Monitoring and Maintenance

### PM2 Process Management

```bash
# View PM2 processes
pct exec <container-id> -- sudo -u wikijs-integration pm2 list

# Monitor process metrics
pct exec <container-id> -- sudo -u wikijs-integration pm2 monit

# Restart specific process
pct exec <container-id> -- sudo -u wikijs-integration pm2 restart wikijs-integration

# View process logs
pct exec <container-id> -- sudo -u wikijs-integration pm2 logs wikijs-integration --lines 50
```

### Log Management

```bash
# View application logs
pct exec <container-id> -- tail -f /var/log/wikijs-integration/combined.log

# Check error logs
pct exec <container-id> -- tail -f /var/log/wikijs-integration/error.log

# Monitor log file sizes
pct exec <container-id> -- du -sh /var/log/wikijs-integration/
```

### Health Monitoring

```bash
# Check service health
curl http://<container-ip>/health

# Monitor service uptime
pct exec <container-id> -- systemctl show wikijs-integration --property=ActiveEnterTimestamp

# Check Node.js process
pct exec <container-id> -- ps aux | grep "server-mcp.js"
```

### Resource Monitoring

```bash
# Check memory usage
pct exec <container-id> -- sudo -u wikijs-integration pm2 show wikijs-integration

# Monitor container resources
pct exec <container-id> -- top -u wikijs-integration

# Check disk usage
pct exec <container-id> -- df -h
```

## 🔄 Updates and Maintenance

### Updating the WikiJS Integration

Re-run the deployment script to update existing installations:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/wikijs-integration.sh)"
```

The script will:
1. Detect existing container
2. Offer update option
3. Update Node.js dependencies
4. Restart PM2 processes
5. Reload systemd services

### Manual Updates

```bash
# Connect to container
pct exec <container-id> -- bash

# Switch to wikijs-integration user
sudo -u wikijs-integration bash

# Navigate to application directory
cd /opt/wikijs-integration

# Update Node.js dependencies
npm update

# Restart PM2 process
pm2 restart wikijs-integration

# Save PM2 configuration
pm2 save
```

### Configuration Updates

```bash
# Update environment variables
pct exec <container-id> -- nano /opt/wikijs-integration/production.env

# Restart service to apply changes
pct exec <container-id> -- systemctl restart wikijs-integration

# Verify configuration
pct exec <container-id> -- sudo -u wikijs-integration pm2 show wikijs-integration
```

## 🔗 Integration Examples

### GitOps Auditor Integration

The WikiJS Integration works seamlessly with the GitOps Auditor:

1. **Repository Monitoring**:
   - GitOps Auditor detects documentation changes
   - Triggers webhooks to WikiJS Integration
   - Synchronizes content with WikiJS

2. **Documentation Workflow**:
   ```
   Git Repository → GitOps Auditor → WikiJS Integration → WikiJS
   ```

3. **Automated Sync**:
   - Changes in Git repositories
   - Automatic conversion to WikiJS format
   - Page creation and updates in WikiJS

### WikiJS API Integration

Connect to WikiJS using the configured API token:

```javascript
const fetch = require('node-fetch');

async function createWikiPage(title, content) {
  const response = await fetch(`${process.env.WIKIJS_URL}/graphql`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.WIKIJS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query: `
        mutation {
          pages {
            create(
              content: "${content}"
              description: "Auto-generated documentation"
              editor: "markdown"
              isPublished: true
              isPrivate: false
              locale: "en"
              path: "${title.toLowerCase().replace(/\s+/g, '-')}"
              tags: ["auto-generated", "gitops"]
              title: "${title}"
            ) {
              responseResult {
                succeeded
                errorCode
                slug
                message
              }
            }
          }
        }
      `
    })
  });
  
  return response.json();
}
```

## 🛠️ Troubleshooting

### Common Issues

1. **Service Won't Start**:
   ```bash
   # Check systemd status
   pct exec <container-id> -- systemctl status wikijs-integration
   
   # Check PM2 status
   pct exec <container-id> -- sudo -u wikijs-integration pm2 status
   
   # Review error logs
   pct exec <container-id> -- journalctl -u wikijs-integration --since "1 hour ago"
   ```

2. **WikiJS Connection Issues**:
   ```bash
   # Test WikiJS connectivity
   pct exec <container-id> -- curl -I http://192.168.1.90:3000
   
   # Verify API token
   pct exec <container-id> -- cat /opt/wikijs-integration/production.env | grep WIKIJS_TOKEN
   
   # Test API endpoint
   curl -H "Authorization: Bearer YOUR_TOKEN" http://192.168.1.90:3000/graphql
   ```

3. **Permission Issues**:
   ```bash
   # Check file ownership
   pct exec <container-id> -- ls -la /opt/wikijs-integration/
   
   # Fix ownership if needed
   pct exec <container-id> -- chown -R wikijs-integration:wikijs-integration /opt/wikijs-integration/
   ```

### Performance Tuning

```bash
# Adjust PM2 memory limit
pct exec <container-id> -- sudo -u wikijs-integration pm2 restart wikijs-integration --max-memory-restart 256M

# Monitor memory usage
pct exec <container-id> -- sudo -u wikijs-integration pm2 monit

# Optimize container resources if needed
pct set <container-id> --memory 2048
```

## 🎯 Next Steps

After successful deployment:

1. **Configure WikiJS API token** with proper permissions
2. **Test service endpoints** to ensure connectivity
3. **Set up GitOps integration** with documentation repositories
4. **Configure monitoring** using health endpoints
5. **Implement custom sync logic** based on your workflow requirements
6. **Set up webhooks** for automatic synchronization

For additional help, see the [Troubleshooting](Troubleshooting) guide or [Architecture & Integration](Architecture-Integration) documentation.