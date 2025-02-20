#!/bin/bash

# Directory containing the yaml files
NETPLAN_DIR="/etc/netplan"

# Loop through all yaml files in the directory
for file in "$NETPLAN_DIR"/*.yaml; do
    echo "Processing file: $file"
    
    # Extract NetworkManager UUID and name
    NM_UUID=$(grep -A 5 "networkmanager:" "$file" | grep "uuid:" | awk '{print $2}' | tr -d '"')
    NM_NAME=$(grep -A 5 "networkmanager:" "$file" | grep "name:" | awk '{print $2}' | tr -d '"')

    # Extract WiFi SSID and password
    SSID=$(grep -A 5 "access-points:" "$file" | grep "access-points:" -A 1 | tail -n 1 | awk -F '"' '{print $2}')
    PASSWORD=$(grep -A 10 "access-points:" "$file" | grep "password:" | awk '{print $2}' | tr -d '"')
    
    # Display the NetworkManager details
    if [ -n "$NM_UUID" ]; then
        echo "NetworkManager UUID: $NM_UUID"
    else
        echo "NetworkManager UUID: Not found"
    fi

    if [ -n "$NM_NAME" ]; then
        echo "NetworkManager Name: $NM_NAME"
    else
        echo "NetworkManager Name: Not found"
    fi

    # Display the WiFi access point details
    if [ -n "$SSID" ]; then
        echo "WiFi SSID: $SSID"
    else
        echo "WiFi SSID: Not found"
    fi

    if [ -n "$PASSWORD" ]; then
        echo "WiFi Password: $PASSWORD"
    else
        echo "WiFi Password: Not found or not required"
    fi

    echo "---------------------------------"
done

