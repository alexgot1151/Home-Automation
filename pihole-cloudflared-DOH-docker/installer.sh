#!/bin/bash

# Install Docker dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common

# Detect Linux distribution
linux_distribution=$(cat /etc/os-release | grep '^ID=' | awk -F'=' '{print $2}')

# Detect Linux version
linux_version=$(cat /etc/os-release | grep '^VERSION_ID=' | awk -F'=' '{print $2}')

# Set Docker repository URL
docker_repo_url="https://download.docker.com/linux/${linux_distribution}/docker-${linux_version}.list"

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/${linux_distribution}/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $docker_repo_url $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt cache
apt-get update

# Install Docker
apt-get install -y docker-ce

# Add current user to the docker group
usermod -aG docker $USER

# Download Pi-hole Docker container
docker run -d --name pihole \
  -e ServerIP=$(hostname -I | awk '{print $1}') \
  -e TZ="Europe/Sofia" \
  -e DNS1="127.0.0.1#5053" \
  -e DNS2="127.0.0.1#5053" \
  -p 53:53/tcp -p 53:53/udp -p 80:80/tcp -p 443:443/tcp \
  -v $HOME/pihole/etc-pihole/:/etc/pihole/ \
  -v $HOME/pihole/etc-dnsmasq.d/:/etc/dnsmasq.d/ \
  -v $HOME/pihole/custom-blocklists/:/etc/pihole/custom-blocklists/ \
  --restart unless-stopped \
  pihole/pihole:latest

# Download blocklists
mkdir -p $HOME/pihole/custom-blocklists/
wget -O $HOME/pihole/custom-blocklists/Easyprivacy.txt https://v.firebog.net/hosts/Easyprivacy.txt
wget -O $HOME/pihole/custom-blocklists/adaway_hosts.txt https://adaway.org/hosts.txt

# Restart Pi-hole container
docker restart pihole

# Download Cloudflared Docker container
docker run -d --name cloudflared \
  -e TUNNEL_DNS_UPSTREAM="https://adblock.dns.mullvad.net/dns-query" \
  -e TUNNEL_DNS_PORT="5053" \
  -p 5053:5053/tcp -p 5053:5053/udp \
  --restart unless-stopped \
  crazymax/cloudflared:latest
