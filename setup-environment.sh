#!/bin/bash

# color palette
green_prefix="\033[32m" # success
blue_prefix="\033[34m" # processing
red_prefix="\033[31m" # error
suffix="\033[00m" #suffix


install_docker() {
    # Update packages:
    echo -e "$blue_prefix"Updating packages..."$suffix"
    sudo apt-get update > /dev/null 2> errors.log
    if [ $? -eq 0 ]; then
        echo -e "$green_prefix"Packages updated."$suffix"
    else
        echo -e "$red_prefix"An error occured while updating packages. Error details have been logged to errors.log."$suffix"
    fi

    # Add Docker's GPG key:
    echo -e "$blue_prefix"Installing ca-certificates and curl..."$suffix"
    sudo apt-get install -y ca-certificates curl > /dev/null 2> errors.log
    if [ $? -eq 0 ]; then
        echo -e "$green_prefix"Installation successful."$suffix"
    else
        echo -e "$red_prefix"An error occured while installing. Error details have been logged to errors.log."$suffix"
    fi

    sudo install -m 0755 -d /etc/apt/keyrings > /dev/null 2> errors.log

    echo -e "$blue_prefix"Downloading and saving GPG key for Docker..."$suffix" 
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc > /dev/null 2>errors.log
    if [ $? -eq 0 ]; then
        echo -e "$green_prefix"Successful."$suffix"
    else
        echo -e "$red_prefix"An error occured while downloading GPG key. Error details have been logged to errors.log."$suffix"
    fi
    sudo chmod a+r /etc/apt/keyrings/docker.asc  > /dev/null 2>&1

    # Add repository to apt sources:
    echo -e "$blue_prefix"Adding repository to apt sources..."$suffix"
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    if [ $? -eq 0 ]; then
        echo -e "$green_prefix"Repository added."$suffix"
    else
        echo -e "$red_prefix"Repository could not added to apt sources."$suffix"
    fi

    echo -e "$blue_prefix"Updating packages..."$suffix"
    sudo apt-get update  > /dev/null 2> errors.log
    if [ $? -eq 0 ]; then
        echo -e "$green_prefix"Packages updated."$suffix"
    else
        echo -e "$red_prefix"An error occured while updating packages. Error details have been logged to errors.log."$suffix"
    fi

    # Install the latest Docker packages:
    echo -e "$blue_prefix"Installing Docker packages..."$suffix"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2> errors.log
    if [ $? -eq 0 ]; then
        echo -e "$green_prefix"Installed Docker successfully."$suffix"
    else
        echo -e "$red_prefix"An error occured while installing Docker. Error details have been logged to errors.log."$suffix"
    fi

    # Enable and start Docker service:
    sudo systemctl enable docker > /dev/null 2>&1
    sudo systemctl start docker > /dev/null 2>&1
}
install_docker


# echo -e "\033[34m----------\nSETTING UP DEV ENVIRONMENT...\n----------\033[0m" 


# Create project directories
mkdir -p ~/dev-env/
mkdir -p ~/dev-env/nginx

# Clone Vue.js repository:
cd ~/dev-env
git clone https://github.com/vuejs/v2.vuejs.org.git
cd ..

# Create Vue.js (Node.js) Dockerfile:
cat <<EOL > ~/dev-env/v2.vuejs.org/Dockerfile
FROM node:18
WORKDIR /app
COPY package.json yarn.lock ./
RUN npm install
COPY . .
EXPOSE 4000
CMD [ "npm", "run", "dev" ]
EOL

# Create Nginx Dockerfile:
cat <<EOL > ~/dev-env/nginx/Dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EOL

# Create Nginx configuration:
cat <<EOL > ~/dev-env/nginx/nginx.conf
upstream localhost {
    server app:4000;
}

server {
    listen 80;
    server_name localhost;
    location / {
        proxy_pass http://localhost;
    }
}
EOL

# Create Docker Compose file
cat <<EOL > ~/dev-env/compose.yaml
services:
  app:
    build: ./v2.vuejs.org
    hostname: app
    ports:
      - "8080:4000"
  nginx:
    build: ./nginx
    ports:
      - "80:80"
    depends_on:
      - app
EOL


# echo -e "\033[32m----------\nDONE\n----------\033[0m"
# echo -e "\033[34m----------\nSTARTING DEV ENVIRONMENT...\n----------\033[0m" 


# Start development environment
cd ~/dev-env
sudo docker-compose up -d
sudo docker-compose down
