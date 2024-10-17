 VISITAR O SITE ORIGINAL: https://help.reacher.email/install-reacher-on-ovh

This guide explains how to install Reacher on an OVH dedicated server.

## Requirements

* Create an account on https://www.ovhcloud.com.
* Buy a dedicated server. I do not recommend using a VPS, as you will be sharing the same IP address with other customers, which can make email verification results unreliable. Computation power is often not the bottleneck, so you can get the cheap dedicated Eco servers.
* Make sure you have the correct license to self-host, see the [Self-Host Guide](link-to-self-host-guide).
* (Only if you want to enable bulk email verification) Have access to a PostgreSQL database. Heroku offers some for free.

## 🤓 Step by Step Guide

1. **Set up your dedicated server** by following the official OVH documentation. I recommend "Debian 11" as the Linux distribution, but it should work with "Debian 10" too.
2. **Log into your server:**

   ```bash
   ssh debian@<ip_address_of_your_server>
Create the file ovh_postinstall.sh and paste the following content into it. You can use vim or nano to do this. Configure the variables at the top of the file accordingly.

Bash
#!/bin/bash

# Postinstall script of Reacher Backend on an OVH debian 11 server.
# As a postinstall, this script is meant to be run once, but for convenience,
# it's actually idempotent.

# Fail early.
set -e

# TODO: Configure these variables.
# Required variables:
RCH_VERSION="v0.7.0"                      # Docker Hub tag for reacherhq/backend.
DATABASE_URL="{{{DATABASE_URL}}}"          # URL of a Postgres database which hosts the bulk queue and results.
# Optional variables
RCH_SENTRY_DSN="{{{RCH_SENTRY_DSN}}}"      # Send bug reports to a Sentry.io dashboard.
RCH_HEADER_SECRET="{{{RCH_HEADER_SECRET}}}"  # Protect backend from the public.
RCH_FROM_EMAIL=reacher@gmail.com
RCH_HELLO_NAME=gmail.com                   # Should ideally match the reverse DNS of your OVH cloud instance.

echo "Installing Reacher backend $RCH_VERSION on host $HOSTNAME..."

# Install Docker
# [https://docs.docker.com/engine/install/debian/](https://docs.docker.com/engine/install/debian/)
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    --yes
sudo mkdir -p /etc/apt/keyrings
curl -fsSL [https://download.docker.com/linux/debian/gpg](https://download.docker.com/linux/debian/gpg)   
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg]   
 [https://download.docker.com/linux/debian](https://download.docker.com/linux/debian)   
 \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install   
 docker-ce docker-ce-cli containerd.io   
 docker-compose-plugin --yes

# Create `docker` group
# [https://docs.docker.com/engine/install/linux-postinstall/](https://docs.docker.com/engine/install/linux-postinstall/)
getent group docker || sudo groupadd docker
sudo usermod -aG docker debian
# Reload users and groups, see
# [https://superuser.com/questions/272061/reload-a-linux-users-group-assignments-without-logging-out](https://superuser.com/questions/272061/reload-a-linux-users-group-assignments-without-logging-out)   

sudo su - $USER << EOF

# Stop all previous docker containers and images
docker stop reacher_backend
docker rm reacher_backend

# Run the backend
docker run -d \
    -e RCH_ENABLE_BULK=1 \
    -e DATABASE_URL=$DATABASE_URL \
    -e RCH_BACKEND_NAME=$HOSTNAME \
    -e RCH_SENTRY_DSN=$RCH_SENTRY_DSN \
    -e RCH_HEADER_SECRET=$RCH_HEADER_SECRET \
    -p 80:8080 \
    --name reacher_backend \
    reacherhq/backend:$RCH_VERSION

echo "Everything set. You can close this terminal."
EOF
Use code with caution.

Make the script executable:

Bash
chmod a+x ovh_postinstall.sh
Use code with caution.

Run the script:

Bash
./ovh_postinstall.sh
Use code with caution.

Wait a couple of minutes until the script finishes. It should end with:

--snip--
<long_hexadecimal_string>
Everything set. You can close this terminal.
The long hexadecimal string represents the Docker container ID, should you wish to start/stop it or monitor its logs.

In a new terminal, test the server by sending an email verification request:

Bash
curl -X POST \
    -H 'Content-Type: application/json' \
    -d '{"to_email":"amaury@reacher.email"}' \
    http://<ip_address_of_your_server>/v0/check_email
Use code with caution.

It should return a JSON with is_reachable=safe!

Next Steps
Your server is now correctly set up.

If you want to configure it more, take a look at some configuration options.
Instead of single email verifications as in step 6, try bulk email verification after setting the RCH_ENABLE_BULK environment variable to 1.
🤔 Something went wrong?
Please email ✉️ amaury@reacher.email with some logs about your error. I run part of Reacher's infrastructure on OVH, so I can help here.
