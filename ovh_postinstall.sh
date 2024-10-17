#!/bin/bash

# Postinstall script of Reacher Backend on an OVH debian 11 server.
# As a postinstall, this script is meant to be run once, but for convenience,
# it's actually idempotent.

# Fail early.
set -e

# TODO: Configure these variables.
# Required variables:
RCH_VERSION=v0.7.0-beta.2                   # Docker Hub tag for reacherhq/backend.
DATABASE_URL=postgresql://postgres:yA585z15.,.,1030@5.161.98.157:5432/reacher          # URL>
# Optional variables
# RCH_SENTRY_DSN="{{{RCH_SENTRY_DSN}}}"         # Send bug reports to a Sentry.io dashboard.
RCH_HEADER_SECRET=d469c70a-5c11-438e-8b60-4fbaac47f499   # Protect backend from the public.
RCH_FROM_EMAIL=frederiquelisboa@gmail.com
RCH_HELLO_NAME=gmail.com
RUST_LOG=info
#RCH_AMQP_ADDR=amqp://root:yA585z15.,.,1030@5.161.98.157:5672/default
#RCH_WORKER_CONCURRENCY=10

echo "Installing Reacher backend $RCH_VERSION on host $HOSTNAME..."

# Install Docker
# https://docs.docker.com/engine/install/debian/
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    --yes
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin --yes

# Create `docker` group
# https://docs.docker.com/engine/install/linux-postinstall/
getent group docker || sudo groupadd docker
sudo usermod -aG docker debian
# Reload users and groups, see
# https://superuser.com/questions/272061/reload-a-linux-users-group-assignments-without-logging-out
sudo su - $USER << EOF

# Stop all previous docker containers and images
docker stop reacher_backend

# Run the backend
docker run -d \
    -e RCH_ENABLE_BULK=0 \
    -e DATABASE_URL=$DATABASE_URL \
    -e RCH_BACKEND_NAME=$HOSTNAME \
    -e RCH_SENTRY_DSN=$RCH_SENTRY_DSN \
    -e RCH_HEADER_SECRET=$RCH_HEADER_SECRET \
    -e RCH_AMQP_ADDR=$RCH_AMQP_ADDR \
    -e RCH_WORKER_CONCURRENCY=$RCH_WORKER_CONCURRENCY \
    -e RUST_LOG=$RUST_LOG \
    -p 80:8080 \
    --name reacher_backend \
    reacherhq/backend:$RCH_VERSION

echo "Everything set. You can close this terminal."
EOF
