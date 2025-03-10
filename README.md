# Media VM Setup Script

## Script Overview

This script automates the setup of a media environment with the following tasks:

- **Xen Guest Tools Installation**: Optionally installs Xen guest tools.
- **User Management**: Adds user to the `sudo` group.
- **OpenSSH Setup**: Installs and enables OpenSSH server.
- **Docker & Docker Compose Installation**: Installs Docker and Docker Compose.
- **Fish Shell Setup**: Installs Fish shell and sets it as the default.
- **TLDR & Ocean Theme**: Installs `tldr` with the Ocean theme.
- **Git Configuration**: Installs Git and sets global username and email.
- **System Tools Installation**: Installs `duf`, `tree`, `micro`, `htop`, `neofetch`, `rsync`.
- **NFS Client Setup**: Installs `nfs-common`, creates a media directory, and configures NFS mount.
- **Docker Containers**: Creates containers for multiple media applications (`qBittorrent`, `Prowlarr`, `Sonarr`, `Radarr`, `Overseerr`, `Plex`, `Jellyfin`), and sets up the `pia-wireguard` container for VPN connection.
- **Docker Compose Setup**: Generates and runs a `docker-compose.yml` file to launch the containers.
- **Portainer Agent Setup**: Configures Portainer agent for Docker management.
- **System Info Display**: Displays system info using `neofetch`, `duf`, and `ip -c a`.
- **Final Setup Instructions**: Shows the NFS media directory structure and qBittorrent login credentials.

## Setup Instructions

Follow these steps to set up your media VM environment:

1. **Download the Script**:
   ```bash
   curl -sS https://raw.githubusercontent.com/connorlance/Media_VM_SCRIPT/main/media_VM_script.sh -o media_VM_script.sh

2. **Make the Script Executable**:
   ```bash
   chmod +x media_VM_script.sh
3. **Swith to sudo user**
   ```bash
   su
5. **Run the Script**:
   ```bash
   bash media_VM_script.sh
