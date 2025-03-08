#!/bin/bash

# Get user info
read -p "Enter your username: " username
read -p "Enter your GitHub username: " git_username
read -p "Enter your GitHub email address: " git_email
read -p "Enter nfs IP and path (server_ip:/mnt/path): " nfs_ip_path
read -p "Enter PIA username: " pia_username
read -p "Enter PIA password: " pia_password

echo "Do you have the Xen guest tools CD-ROM connected and want to install Xen guest tools? (yes/no)"
read answer
if [ "$answer" == "yes" ]; then
    echo "Proceeding with the installation..."
    # Set temporary path to avoid potential errors
    export PATH=$PATH:/sbin:/usr/sbin
    sudo mount /dev/cdrom /mnt
    sudo bash /mnt/Linux/install.sh
else
    echo "Installation canceled."
fi

# Add user to sudo group
echo "Enter sudo password"
sudo usermod -aG sudo $username

# Enable SSH
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Install Docker and Docker Compose
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '(?<=\"tag_name\": \")[^\"]*')" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker $username

# Install fish shell
sudo apt install fish -y
chsh -s /usr/bin/fish $username

# Install tldr
sudo apt install nodejs npm -y
curl -s https://tldr.sh/assets/tldr.zip -o /tmp/tldr.zip && unzip -o /tmp/tldr.zip -d ~/.tldr
echo "alias tldr='tldr --theme ocean'" >> ~/.config/fish/config.fish

# Install Git
sudo apt install git -y
git config --global user.name "$git_username"
git config --global user.email "$git_email"

# Install tools
sudo apt install duf -y
sudo apt-get install tree -y
sudo apt-get install micro -y
sudo apt install htop -y
sudo apt install neofetch -y

#Install nfs
sudo apt install -y nfs-common

#Create nfs media mount
sudo mkdir -p /mnt/media
sudo mount $nfs_ip_path /mnt/media
df -h
sudo bash -c "echo \"$nfs_ip_path /mnt/media nfs defaults,nofail,retry=25 0 0\" >> /etc/fstab"

# Create docker containers
cd /home/$username
sudo mkdir docker
cd /home/$username/docker
sudo mkdir jellyfin
sudo mkdir overseerr
sudo mkdir plex
sudo mkdir prowlarr
sudo mkdir qbittorrent
sudo mkdir radarr
sudo mkdir sonarr

sudo tee docker-compose.yml > /dev/null <<EOF
services:
  wireguard-pia:
    image: thrnz/docker-wireguard-pia:latest
    container_name: wireguard-pia
    environment:
      - LOC=br
      - USER=$pia_username
      - PASS=$pia_password
      - LOCAL_NETWORK=192.168.200.0/24
      - VPNDNS=8.8.8.8,8.8.4.4
      - PORT_FORWARDING=1
      - FIREWALL=1
      - KEEPALIVE=25
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "9696:9696"
      - "7878:7878"
      - "8989:8989"
    networks:
      - pia_network

  qbittorrent:
    container_name: qbittorrent
    image: lscr.io/linuxserver/qbittorrent
    environment:
      - WEBUI_PORT=8080
      - WEBUI_USERNAME=admin
      - WEBUI_PASSWORD=adminadmin
      - PUID=0
      - PGID=0
    volumes:
      - ./qbittorrent/config:/config
      - /mnt/media/downloads:/tv/downloads
    depends_on:
      - wireguard-pia
    network_mode: "service:wireguard-pia"
    restart: unless-stopped

  prowlarr:
    container_name: prowlarr
    image: lscr.io/linuxserver/prowlarr:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./prowlarr/config:/config
    depends_on:
      - wireguard-pia
    network_mode: "service:wireguard-pia"
    restart: unless-stopped

  sonarr:
    container_name: sonarr
    image: lscr.io/linuxserver/sonarr:latest
    environment:
      - PUID=0
      - PGID=0
      - TZ=America/New_York
    volumes:
      - ./sonarr/config:/config
      - /mnt/media:/tv
    depends_on:
      - wireguard-pia
    network_mode: "service:wireguard-pia"
    restart: unless-stopped

  radarr:
    container_name: radarr
    image: lscr.io/linuxserver/radarr:latest
    environment:
      - PUID=0
      - PGID=0
      - TZ=America/New_York
    volumes:
      - ./radarr/config:/config
      - /mnt/media:/tv
    depends_on:
      - wireguard-pia
    network_mode: "service:wireguard-pia"
    restart: unless-stopped

  overseerr:
    container_name: overseerr
    image: sctx/overseerr:latest
    environment:
      - TZ=America/New_York
      - PUID=0
      - PGID=0
    volumes:
      - ./overseerr/config:/app/config
    ports:
      - "5055:5055"
    depends_on:
      - sonarr
      - radarr
    restart: unless-stopped
    networks:
      - pia_network

  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - PLEX_CLAIM=claim-pfyM8KWxsi8944DowkBD
      - VERSION=docker
    volumes:
      - ./plex/config:/config
      - /mnt/media:/media
      - ./plex/transcode:/transcode
    network_mode: host
    restart: unless-stopped

  jellyfin:
    container_name: jellyfin
    image: jellyfin/jellyfin:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./jellyfin/config:/config
      - /mnt/media:/media
    network_mode: host
    restart: unless-stopped

networks:
  pia_network:
    driver: bridge
EOF


# Display system info and tools
neofetch
duf
ip -c a

#Echo information
echo " "
echo "Ensure that /mnt/media contains this structure (created with sudo mkdir):"
echo "
/mnt/media
├── downloads
├── tv
└── movie
"
sudo tree /mnt/media
echo " "
echo "Use docker compose up without -d, to get the login password for qbittorrent"

# Exit su session
exit
