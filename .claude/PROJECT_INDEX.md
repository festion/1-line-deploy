# 1-line-deploy Project Index

Generated: 2026-02-03

## Purpose
This project provides a set of one-line deployment scripts for setting up various homelab infrastructure components. The goal is to enable the deployment of production-ready services with a single command, primarily targeting Proxmox VE environments. The scripts automate the process of creating LXC containers, installing dependencies, and configuring services.

## Directory Structure
```
.
├── ct/
│   ├── homepage.sh           # Deployment script for Homepage Dashboard
│   ├── netbox-agent.sh       # Deployment script for NetBox Agent
│   ├── proxmox-agent.sh      # Deployment script for Proxmox Agent Dashboard
│   └── wikijs-integration.sh # Deployment script for WikiJS Integration
├── .git/                     # Git version control directory
├── *.md                      # Markdown files for documentation
└── ...
```

## Key Files
- `README.md`: The main documentation file, providing an overview of the available deployments, usage instructions, and architecture.
- `ct/homepage.sh`: A shell script that automates the deployment of a Homepage dashboard container.
- `ct/netbox-agent.sh`: A shell script for deploying a NetBox Agent container for infrastructure discovery.
- `ct/proxmox-agent.sh`: A shell script for deploying a Proxmox cluster monitoring dashboard.
- `ct/wikijs-integration.sh`: A shell script for deploying a WikiJS integration service for GitOps document management.

## Architecture Patterns
The project follows a consistent architecture pattern for all deployments:
- **One-Line Deployment:** Each service is deployed using a single `bash -c "$(curl -fsSL ...)"` command, making it easy to get started.
- **Proxmox VE Target:** The scripts are designed to run on a Proxmox VE 8.0 (or later) host.
- **LXC Containers:** Each service is deployed in its own unprivileged Debian 12 LXC container, providing isolation and resource management.
- **Automated Provisioning:** The scripts handle the entire lifecycle of the container, from creation and dependency installation to service configuration.
- **Update Mechanism:** The scripts can detect existing containers for the same service and offer to update the installation instead of creating a new one.
- **Systemd Services:** The applications within the containers are managed by systemd services (or similar process managers like PM2/Supervisor) to ensure they run on startup and are restarted on failure.

## Entry Points
The main entry points for this project are the one-line deployment commands for each service:
- **Homepage Dashboard:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/homepage.sh)"`
- **WikiJS Integration:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/wikijs-integration.sh)"`
- **NetBox Agent:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/netbox-agent.sh)"`
- **Proxmox Agent Dashboard:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/festion/1-line-deploy/main/ct/proxmox-agent.sh)"`

## Dependencies
- **Proxmox VE 8.0 or later:** The deployment scripts are designed to run on a Proxmox host.
- **Internet Connection:** Required for downloading LXC templates, Git repositories, and package dependencies.

## Common Tasks
- **Deploying a new service:** Run the corresponding one-line deployment command on the Proxmox host.
- **Updating an existing service:** Re-run the same one-line deployment command. The script will detect the existing container and prompt for an update.
- **Local Testing:** Serve the scripts locally using a Python HTTP server and then execute them using `curl` with a `localhost` URL, as described in the `README.md`.
