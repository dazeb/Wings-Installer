#!/bin/bash

# Set the GitHub repository URL and script names
repo_url="https://raw.githubusercontent.com/your-username/your-repo/main"
scripts=(
  "install_dependencies.sh"
  "install_wings.sh"
  "configure_wings.sh"
  "start_wings.sh"
  "daemonize_wings.sh"
)

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

# Download and execute each script
for script in "${scripts[@]}"; do
  coloredEcho green "Downloading $script..."
  if curl -sSL "$repo_url/$script" -o "$script"; then
    coloredEcho green "Successfully downloaded $script."
  else
    coloredEcho red "Failed to download $script. Please check your internet connection and repository URL."
    exit 1
  fi

  chmod +x "$script"
  coloredEcho green "Executing $script..."
  if ./"$script"; then
    coloredEcho green "Successfully executed $script."
  else
    coloredEcho red "Failed to execute $script. Please check the script contents and permissions."
    exit 1
  fi
  echo "------------------------------------"

  # Prompt the user to continue or exit
  read -p "Press Enter to continue or type 'exit' to quit: " user_input
  if [[ $user_input == "exit" ]]; then
    coloredEcho green "Installation process terminated by the user."
    exit 0
  fi
done

coloredEcho green "Installation and configuration complete!"
