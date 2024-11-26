#!/bin/bash

# Kode warna
RED="\033[1;31m"
LIGHT_GREEN="\033[1;92m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

# Fungsi untuk mengecek apakah perintah terakhir berhasil
check_command_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌  Terjadi kesalahan. Periksa pesan di atas untuk detailnya.${RESET}"
        exit 1
    fi
}

# Memeriksa apakah Docker sudah terpasang
if command -v docker &> /dev/null; then
    echo -e "${LIGHT_GREEN}✅  Docker sudah terinstal. Melewati langkah instalasi Docker...${RESET}"
else
    # Memperbarui sistem
    echo -e "\n${BLUE}🔄  Memperbarui daftar paket...${RESET}"
    sudo apt-get update -y && sudo apt-get upgrade -y
    check_command_success

    # Menginstal dependensi yang diperlukan
    echo -e "\n${BLUE}📦  Menginstal dependensi...${RESET}"
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    check_command_success

    # Menambahkan GPG key resmi Docker
    echo -e "\n${CYAN}🔑  Menambahkan GPG key Docker...${RESET}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    check_command_success

    # Menambahkan repository Docker
    echo -e "\n${CYAN}📂  Menambahkan repository Docker...${RESET}"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_command_success

    # Memperbarui daftar paket untuk repository baru
    echo -e "\n${BLUE}🔄  Memperbarui daftar paket untuk repository Docker...${RESET}"
    sudo apt-get update -y
    check_command_success

    # Menginstal Docker
    echo -e "\n${CYAN}🐳  Menginstal Docker CE...${RESET}"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    check_command_success

    # Menambahkan pengguna ke grup Docker
    echo -e "\n${CYAN}👤  Menambahkan pengguna Anda ke grup Docker agar dapat menggunakan Docker tanpa sudo...${RESET}"
    sudo usermod -aG docker $USER
    check_command_success

    # Memberikan informasi logout untuk grup Docker
    echo -e "\n${YELLOW}⚠️   Untuk menggunakan Docker tanpa sudo, Anda perlu logout dan login kembali, atau jalankan perintah ini:${RESET}"
    echo -e "${WHITE}     newgrp docker${RESET}\n"
fi

# Memeriksa apakah Docker Compose sudah terpasang
if command -v docker-compose &> /dev/null; then
    echo -e "${LIGHT_GREEN}✅  Docker Compose sudah terinstal. Melewati langkah instalasi Docker Compose...${RESET}"
else
    # Menginstal Docker Compose
    echo -e "\n${BLUE}📦  Menginstal Docker Compose...${RESET}"
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    check_command_success
fi

# Menguji instalasi
echo -e "\n${LIGHT_GREEN}✅  Menguji instalasi Docker dan Docker Compose...${RESET}"
docker --version
docker-compose --version

# Meminta pengguna untuk memasukkan Private Key
echo -e "\n${CYAN}🔐  Masukkan Private Key Anda:${RESET}"
read -s YOUR_PRIVATE_KEY  # Input tersembunyi untuk keamanan

# Validasi input
if [ -z "$YOUR_PRIVATE_KEY" ]; then
    echo -e "\n${RED}❌  Private Key tidak boleh kosong. Silakan coba lagi.${RESET}"
    exit 1
fi

# Menjalankan perintah Docker
echo -e "\n${CYAN}🔄  Menjalankan Docker container dengan Private Key yang diberikan...${RESET}"
CONTAINER_NAME="glacier-verifier"
docker run -d -e PRIVATE_KEY=$YOUR_PRIVATE_KEY --name $CONTAINER_NAME docker.io/glaciernetwork/glacier-verifier:v0.0.2

# Verifikasi apakah container berhasil dijalankan
if [ $? -eq 0 ]; then
    echo -e "\n${LIGHT_GREEN}✅  Docker container '$CONTAINER_NAME' berhasil dijalankan!${RESET}"
else
    echo -e "\n${RED}❌  Gagal menjalankan Docker container. Periksa log untuk detailnya.${RESET}"
    exit 1
fi

# Opsi untuk menampilkan log
echo -e "\n${YELLOW}📋  Apakah Anda ingin melihat log container '$CONTAINER_NAME' sekarang? (y/n)${RESET}"
read -r SHOW_LOGS

if [ "$SHOW_LOGS" == "y" ] || [ "$SHOW_LOGS" == "Y" ]; then
    echo -e "\n${BLUE}🔍  Menampilkan log container '$CONTAINER_NAME':${RESET}"
    docker logs -f $CONTAINER_NAME
else
    echo -e "\n${LIGHT_GREEN}✅  Instalasi selesai. Anda dapat melihat log kapan saja dengan perintah:${RESET}"
    echo -e "${WHITE}     docker logs -f $CONTAINER_NAME${RESET}\n"
fi


