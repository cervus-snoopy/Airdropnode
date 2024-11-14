#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Ensure script is run as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${GREEN}This script requires root access. Please run it as root or use 'sudo'.${NC}"
    exit 1
fi

# Update system and install dependencies
echo -e "${GREEN}Updating system and installing dependencies...${NC}"
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo -e "${GREEN}Adding Docker's official GPG key...${NC}"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo -e "${GREEN}Adding Docker repository...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update again and install Docker and Docker Compose
echo -e "${GREEN}Installing Docker Engine and Docker Compose...${NC}"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
echo -e "${GREEN}Verifying Docker installation...${NC}"
docker --version
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker successfully installed!${NC}"
else
    echo -e "${GREEN}Error installing Docker.${NC}"
    exit 1
fi

# Clone the repository and navigate to grass/data directory
echo -e "${GREEN}Cloning repository...${NC}"
git clone https://github.com/MsLolita/grass.git
cd grass || { echo "Failed to navigate to the grass directory. Ensure the grass directory exists."; exit 1; }
cd data || { echo "Failed to navigate to the data directory. Ensure the data directory exists within grass."; exit 1; }

# Replace accounts.txt and proxies.txt
echo -e "${GREEN}Setting up accounts and proxies...${NC}"
read -p "Enter your email: " email
read -s -p "Enter your password: " password
echo -e "${email}:${password}" > accounts.txt
echo -e "\nAccounts updated in accounts.txt."

echo -e "\nEnter proxy addresses, one per line (finish with an empty line):"
> proxies.txt  # Clear existing proxies
while true; do
    read -p "Proxy: " proxy
    [[ -z "$proxy" ]] && break
    echo "$proxy" >> proxies.txt
done
echo -e "Proxies updated in proxies.txt."

# Modify config.py parameters
echo -e "${GREEN}Updating config.py...${NC}"
sed -i 's/^THREADS = .*/THREADS = 5/' config.py
sed -i 's/^MIN_PROXY_SCORE = .*/MIN_PROXY_SCORE = 50/' config.py
sed -i 's/^APPROVE_EMAIL = .*/APPROVE_EMAIL = False/' config.py
sed -i 's/^CONNECT_WALLET = .*/CONNECT_WALLET = False/' config.py
sed -i 's/^SEND_WALLET_APPROVE_LINK_TO_EMAIL = .*/SEND_WALLET_APPROVE_LINK_TO_EMAIL = False/' config.py
sed -i 's/^APPROVE_WALLET_ON_EMAIL = .*/APPROVE_WALLET_ON_EMAIL = False/' config.py
sed -i 's/^SEMI_AUTOMATIC_APPROVE_LINK = .*/SEMI_AUTOMATIC_APPROVE_LINK = False/' config.py
sed -i 's/^CLAIM_REWARDS_ONLY = .*/CLAIM_REWARDS_ONLY = False/' config.py
sed -i 's/^STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = .*/STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = True/' config.py
sed -i 's/^CHECK_POINTS = .*/CHECK_POINTS = False/' config.py
sed -i 's/^SHOW_LOGS_RARELY = .*/SHOW_LOGS_RARELY = False/' config.py
sed -i 's/^MINING_MODE = .*/MINING_MODE = True/' config.py
sed -i 's/^REGISTER_ACCOUNT_ONLY = .*/REGISTER_ACCOUNT_ONLY = False/' config.py
sed -i 's/^REGISTER_DELAY = .*/REGISTER_DELAY = (3, 7)/' config.py
echo -e "Configuration updated in config.py."

# Navigate back to grass directory to build and run Docker container
cd ..
echo -e "${GREEN}Starting Docker containers with Docker Compose...${NC}"
docker-compose up -d

# Build Docker image
echo -e "${GREEN}Building Docker image...${NC}"
if [ -f "Dockerfile" ]; then
    docker build -t grass-app .
else
    echo "Dockerfile not found. Please ensure the Dockerfile is in the grass directory."
    exit 1
fi

# Run Docker container
echo -e "${GREEN}Running the Docker container...${NC}"
docker run grass-app

echo -e "${GREEN}All operations completed successfully!${NC}"
