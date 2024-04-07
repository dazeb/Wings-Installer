#!/bin/bash

# Prompt the user for the configuration code block
read -p "Please enter the configuration code block from the Panel: " config

# Write the configuration to config.yml
echo "$config" > /etc/pterodactyl/config.yml
