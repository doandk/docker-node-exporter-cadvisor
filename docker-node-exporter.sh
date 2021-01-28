#!/bin/bash

if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  ## Setup Docker if Not Installed
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  systemctl enable docker
else
  echo "Docker-ce already installed"
fi


if ! docker-compose version >/dev/null 2>&1; then
  ## Setup Docker-Compose
  echo "Installing docker-compose..."
  sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  docker-compose --version
else
    echo "Docker-compose already installed"
fi


cat <<EOF > docker-compose.exporters.yml
version: '2.1'

services:

  nodeexporter:
    image: prom/node-exporter:v1.0.1
    container_name: nodeexporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
    network_mode: host
    labels:
      org.label-schema.group: "monitoring"

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.38.7
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /cgroup:/cgroup:ro
    restart: unless-stopped
    network_mode: host
    labels:
      org.label-schema.group: "monitoring"
EOF

docker-compose -f docker-compose.exporters.yml up -d

docker ps

## Additional Firewall Rules if Needed
# sudo ufw allow from 10.104.0.0/20 to any port 9100

exit 0
