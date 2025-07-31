#!/bin/bash
set -e

# Install Java prerequisite
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre

# Verify Java
java -version

# Add Jenkins GPG key and repo
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update

# Install Jenkins
sudo apt-get install -y jenkins

# Enable and start service
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

# Firewall (if ufw enabled)
sudo ufw allow 8080
sudo ufw reload

# Initial setup: Access http://192.168.10.36:8080, unlock with password
echo "Initial admin password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
echo "Complete wizard in browser: Install suggested plugins."
