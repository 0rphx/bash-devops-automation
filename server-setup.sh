#!/bin/bash

#############################################
# DevOps Server Setup Script
# Author: Oreoluwa Olusinde
# Description: Basic Ubuntu server setup
#############################################

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root."
  echo "Please run: sudo ./server-setup.sh"
  exit 1
fi

echo "Starting DevOps server setup..."

# Update system
echo "Updating system packages..."
apt update -y \
&& apt upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools \
  ufw \
  ca-certificates \
  gnupg \
  lsb-release

# Install Docker
echo "Checking if Docker is installed..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."

  mkdir -p /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor \
  -o /etc/apt/keyrings/docker.gpg

  echo "Adding Docker repository..."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

  apt update -y

  apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  systemctl start docker
  systemctl enable docker

  echo "Docker installation completed."
else
  echo "Docker is already installed."
fi

# Install docker-compose (standalone)
echo "Checking if docker-compose is installed..."
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "Installing docker-compose..."

  curl -L \
  https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m) \
  -o /usr/local/bin/docker-compose

  chmod +x /usr/local/bin/docker-compose

  echo "docker-compose installation completed."
else
  echo "docker-compose is already installed."
fi

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80
ufw allow 443

# Optional DevOps user creation
read -p "Do you want to create a DevOps user? (y/n): " create_user

if [ "$create_user" = "y" ]; then
  read -p "Enter username: " username

  if id "$username" >/dev/null 2>&1; then
    echo "User already exists."
  else
    useradd -m -s /bin/bash "$username"
    usermod -aG sudo "$username"
    usermod -aG docker "$username"
    echo "User $username created and added to sudo and docker groups."
  fi
fi

# Verify installations
echo "Verifying installations..."
docker --version
docker-compose --version
git --version

# Save setup information
echo "Saving setup details..."
cat > /root/server-setup-info.txt << EOF
Server Setup Completed: $(date)
Docker: $(docker --version)
Docker Compose: $(docker-compose --version)
Git: $(git --version)
Firewall: Enabled
EOF

echo "Setup complete. Server is ready for DevOps work."
echo "Details saved in /root/server-setup-info.txt"

