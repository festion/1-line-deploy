# MCP Server Configuration

This project is configured with a comprehensive Model Context Protocol (MCP) server suite to enhance development workflows and homelab integration.

## Configured MCP Servers

### Core Infrastructure (4 servers)

#### 1. filesystem
- **Package**: `@modelcontextprotocol/server-filesystem`
- **Purpose**: Local file system access for the 1-line-deploy project
- **Scope**: `/home/dev/workspace/1-line-deploy`

#### 2. network-fs
- **Package**: `@modelcontextprotocol/server-network-fs`
- **Purpose**: Network file system operations
- **Features**: Remote file access, network storage integration

#### 3. serena-enhanced
- **Package**: `@anthropic-labs/serena-enhanced-mcp`
- **Purpose**: Advanced AI assistant with semantic code tools
- **Features**: Code analysis, refactoring suggestions, semantic understanding

#### 4. github
- **Package**: `@modelcontextprotocol/server-github`
- **Purpose**: GitHub repository management
- **Authentication**: Uses personal access token for festion organization
- **Features**: Repository operations, issue management, pull requests

### Development Tools (2 servers)

#### 5. code-linter
- **Package**: `@anthropic-labs/code-linter-mcp`
- **Purpose**: Code quality and linting tools
- **Features**: Multi-language linting, style checking, best practices

#### 6. directory-polling
- **Package**: `@anthropic-labs/directory-polling-mcp`
- **Purpose**: File system monitoring
- **Scope**: `/home/dev/workspace/1-line-deploy`
- **Features**: Real-time file change detection, automated triggers

### Homelab Integration (3 servers)

#### 7. home-assistant
- **Primary**: Docker container (`ghcr.io/home-assistant/mcp-server-homeassistant`)
- **Fallback**: Python module (`mcp_server_homeassistant`)
- **Purpose**: Home Assistant integration
- **Configuration**: 
  - URL: `http://192.168.1.10:8123`
  - Token: (configure in environment)

#### 8. proxmox-mcp
- **Package**: Python module (`proxmox_mcp_server`)
- **Purpose**: Proxmox virtualization management
- **Configuration**:
  - Host: `https://proxmox.homelab.local:8006`
  - User: `api@pve`
  - Token: (configure in environment)
  - SSL verification disabled for homelab

#### 9. truenas
- **Package**: Python module (`truenas_mcp_server`)
- **Purpose**: TrueNAS storage management
- **Configuration**:
  - Host: `https://truenas.homelab.local`
  - API Key: (configure in environment)
  - SSL verification disabled for homelab

## Configuration Files

### 1-line-deploy Project
- **Location**: `/home/dev/workspace/1-line-deploy/.claude.json`
- **Scope**: Deployment scripts and infrastructure

### netbox-agent Project
- **Location**: `/home/dev/workspace/netbox-agent/.claude.json`
- **Scope**: NetBox Agent development and integration

## Environment Variables

Create a `.env` file in each project root with the following variables:

```bash
# GitHub Integration
GITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here

# Home Assistant Integration
HA_URL=http://192.168.1.10:8123
HA_TOKEN=your_home_assistant_token_here

# Proxmox Integration
PROXMOX_HOST=https://proxmox.homelab.local:8006
PROXMOX_USER=api@pve
PROXMOX_TOKEN_ID=your_proxmox_token_id
PROXMOX_TOKEN_SECRET=your_proxmox_token_secret
PROXMOX_VERIFY_SSL=false

# TrueNAS Integration
TRUENAS_HOST=https://truenas.homelab.local
TRUENAS_API_KEY=your_truenas_api_key
TRUENAS_VERIFY_SSL=false
```

## Global Shortcuts

### 1-line-deploy
- **Ctrl+Shift+M**: Quick MCP server status check

### netbox-agent
- **Ctrl+Shift+N**: NetBox Agent quick actions

## Installation

The MCP servers are automatically installed via `npx` when first accessed. For Python-based servers, ensure the following packages are available:

```bash
# Install Python MCP servers
pip install mcp-server-homeassistant
pip install proxmox-mcp-server
pip install truenas-mcp-server
```

## Usage

Once configured, Claude Code will automatically connect to these MCP servers when working in the respective project directories. The servers provide enhanced capabilities for:

- **File Operations**: Advanced file system access and monitoring
- **Code Quality**: Automated linting and code analysis
- **Repository Management**: GitHub operations and version control
- **Homelab Integration**: Direct access to Home Assistant, Proxmox, and TrueNAS
- **Infrastructure Automation**: Deployment script enhancement and monitoring

## Troubleshooting

### Server Connection Issues
1. Check that the MCP server packages are installed
2. Verify environment variables are set correctly
3. Test network connectivity to homelab services
4. Check authentication tokens and API keys

### Authentication Problems
1. Regenerate GitHub personal access token
2. Create new Home Assistant long-lived access token
3. Verify Proxmox API token permissions
4. Check TrueNAS API key scope

### Network Connectivity
1. Ensure homelab services are accessible
2. Check SSL certificate issues (disabled in config for homelab)
3. Verify firewall rules and port accessibility
4. Test direct API calls to services

## Security Considerations

- **API Tokens**: Store sensitive tokens in environment variables, not in code
- **SSL Verification**: Disabled for homelab services but should be enabled for production
- **Network Access**: MCP servers run with network access to homelab infrastructure
- **File Permissions**: Filesystem servers have access to project directories

## Integration Benefits

This MCP configuration provides:
- **Seamless Development**: Enhanced file operations and code quality
- **Homelab Awareness**: Direct integration with infrastructure services
- **Automated Workflows**: File monitoring and change detection
- **Quality Assurance**: Automated linting and code analysis
- **Version Control**: Enhanced GitHub operations and repository management

The configuration is tailored specifically for homelab development workflows and infrastructure automation projects.