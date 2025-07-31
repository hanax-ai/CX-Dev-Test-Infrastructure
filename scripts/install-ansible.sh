#!/bin/bash
set -e

# Install prerequisites
sudo apt update
sudo apt install -y software-properties-common

# Add Ansible PPA
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install -y ansible

# Verify
ansible --version
