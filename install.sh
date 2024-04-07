#!/bin/bash

# Function to display colored text
function coloredEcho() {
  local color=$1
  local message=$2
  case $color in
    green) echo -e "\033[32m$message\033[0m" ;;
    red) echo -e "\033[31m$message\033[0m" ;;
    *) echo "$message" ;;
  esac
}

# Install whiptail if not already installed
if ! command -v whiptail &> /dev/null; then
  coloredEcho green "Installing whiptail..."
  apt update
  apt install -y whiptail
fi

# Function to get available storage locations
function getStorageLocations() {
  pvesm status 2>/dev/null | awk '/^[a-z]/ {print $1}'
}

# Function to get available storage content types
function getStorageContentTypes() {
  echo -e "images\nrootdir\nvztmpl\nbackup\niso\nsnippets"
}

# Prompt the user to select storage for the template
coloredEcho green "Select storage location for the template:"
template_storage=$(whiptail --title "Template Storage" --menu "Choose a storage location for the template" 15 60 5 $(getStorageLocations) 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  coloredEcho red "Template storage selection canceled or failed. Exit status: $exitstatus"
  coloredEcho red "Error output (if any): $(getStorageLocations 2>&1)"
  exit 1
fi

# Prompt the user to select storage for the container
coloredEcho green "Select storage location for the container:"
container_storage=$(whiptail --title "Container Storage" --menu "Choose a storage location for the container" 15 60 5 $(getStorageLocations) 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  coloredEcho red "Container storage selection canceled or failed. Exit status: $exitstatus"
  coloredEcho red "Error output (if any): $(getStorageLocations 2>&1)"
  exit 1
fi

# Prompt the user to select content type for the container storage
coloredEcho green "Select content type for the container storage:"
container_content_type=$(whiptail --title "Container Content Type" --menu "Choose a content type for the container storage" 15 60 6 $(getStorageContentTypes) 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  coloredEcho red "Container content type selection canceled or failed. Exit status: $exitstatus"
  exit 1
fi

# Set the container ID and hostname
CTID=101
HOSTNAME="wings-container"

# Prompt the user for a password (optional)
PASSWORD=$(whiptail --title "Container Password" --inputbox "Enter a password for the container (leave empty for passwordless login):" 10 60 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  coloredEcho red "Password input canceled. Exiting."
  exit 1
fi

# Set the GitHub repository URL and branch
repo_url="https://raw.githubusercontent.com/dazeb/Wings-Installer/main"
branch="main"

# Set the script names
scripts=(
  "install_dependencies_ubuntu.sh"
  "install_wings_ubuntu.sh"
  "configure_wings_ubuntu.sh"
  "start_wings_ubuntu.sh"
  "daemonize_wings_ubuntu.sh"
)

# Create the LXC container
coloredEcho green "Creating LXC container..."
if [ -z "$PASSWORD" ]; then
  pct create $CTID $template_storage:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst --hostname $HOSTNAME --ssh-public-keys ~/.ssh/id_rsa.pub --unprivileged 1 --net0 name=eth0,bridge=vmbr0,ip=dhcp --storage $container_storage --ostype ubuntu
else
  pct create $CTID $template_storage:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst --hostname $HOSTNAME --password $PASSWORD --unprivileged 1 --net0 name=eth0,bridge=vmbr0,ip=dhcp --storage $container_storage --ostype ubuntu
fi

# Set the container storage content type
pct set $CTID --storage $container_storage --content $container_content_type

# Start the container
coloredEcho green "Starting the container..."
pct start $CTID

# Wait for the container to start
sleep 10

# Update and upgrade the container
coloredEcho green "Updating and upgrading the container..."
pct exec $CTID -- apt update
pct exec $CTID -- apt upgrade -y

# Download and execute each script inside the container
for script in "${scripts[@]}"; do
  coloredEcho green "Downloading $script..."
  pct exec $CTID -- curl -sSL "$repo_url/$branch/$script" -o "/root/$script"
  pct exec $CTID -- chmod +x "/root/$script"

  coloredEcho green "Executing $script..."
  if pct exec $CTID -- "/root/$script"; then
    coloredEcho green "Successfully executed $script."
  else
    coloredEcho red "Failed to execute $script. Please check the script contents and permissions."
    exit 1
  fi
  echo "------------------------------------"
done

coloredEcho green "Installation and configuration complete!"
