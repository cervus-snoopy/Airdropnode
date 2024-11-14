#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script requires root privileges. Please run as root or use 'sudo'.${NC}"
    exit 1
fi

# Update and upgrade system packages
echo -e "${GREEN}Updating and upgrading system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is already installed. Skipping Docker installation.${NC}"
    docker --version
else
    # Update and install required dependencies
    echo -e "${GREEN}Updating system and installing dependencies...${NC}"
    if ! apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release; then
        echo -e "${RED}Failed to update and install dependencies.${NC}"
        exit 1
    fi

    # Add Docker’s official GPG key
    echo -e "${GREEN}Adding Docker's official GPG key...${NC}"
    mkdir -p /etc/apt/keyrings
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        echo -e "${RED}Failed to add Docker's GPG key.${NC}"
        exit 1
    fi

    # Set up the Docker repository
    echo -e "${GREEN}Adding Docker repository...${NC}"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine and components
    echo -e "${GREEN}Installing Docker Engine...${NC}"
    if ! apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        echo -e "${RED}Failed to install Docker Engine.${NC}"
        exit 1
    fi
fi

# Verify Docker installation
echo -e "${GREEN}Verifying Docker installation...${NC}"
if docker --version; then
    echo -e "${GREEN}Docker successfully installed!${NC}"
else
    echo -e "${RED}Error occurred during Docker installation.${NC}"
    exit 1
fi

# Install Docker Compose (standalone)
echo -e "${GREEN}Installing Docker Compose...${NC}"
DOCKER_COMPOSE_VERSION="v2.2.3"  # Change to the desired version
if curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed successfully!${NC}"
else
    echo -e "${RED}Failed to download Docker Compose.${NC}"
    exit 1
fi

# Verify Docker Compose installation
if docker-compose --version; then
    echo -e "${GREEN}Docker Compose version: $(docker-compose --version)${NC}"
else
    echo -e "${RED}Error verifying Docker Compose installation.${NC}"
    exit 1
fi

# Add current user to Docker group
echo -e "${GREEN}Adding current user to the Docker group...${NC}"
if usermod -aG docker $USER; then
    echo -e "${GREEN}User successfully added to Docker group. Please log out and log back in to apply changes.${NC}"
else
    echo -e "${RED}Failed to add user to Docker group.${NC}"
fi

# Prompt for username (email) and password for the Docker container
echo -e "${GREEN}Enter your email for the Docker container:${NC}"
read -p "Email: " USER_EMAIL
echo -e "${GREEN}Enter your password for the Docker container:${NC}"
read -s -p "Password: " USER_PASSWORD
echo ""

# Confirm inputs and start Docker container
echo -e "${GREEN}Starting Docker container with provided credentials...${NC}"
docker run -d --name grass-node -h my_device \
    -e USER_EMAIL="${USER_EMAIL}" \
    -e USER_PASSWORD="${USER_PASSWORD}" \
    -p 5900:5900 -p 6080:6080 airdropnode/grass-node

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker container 'grass-node' started successfully!${NC}"
else
    echo -e "${RED}Failed to start the Docker container.${NC}"
    exit 1
fi

# Join Channel Telegram
echo -e "\n👉 ${BOLD}[Join Airdroplegitsss](https://t.me/airdroplegitsss)👈${NC}"