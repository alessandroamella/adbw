#!/bin/bash

TARGET_HOSTNAME="alessandro.amella-everest.nord"

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Connect to an Android device wirelessly via ADB.

Options:
  -h, --help      Show this help message and exit
  -r, --restart   Restart ADB server before connecting

Description:
  This script enables ADB wireless connection to your Android device.
  It automatically detects the device's IP address or prompts for manual input.
  
Examples:
  $(basename "$0")           # Normal wireless connection
  $(basename "$0") -r        # Restart ADB server and connect
  $(basename "$0") --help    # Show this help message

EOF
    exit 0
}

# Parse command line arguments
RESTART_ADB=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -r|--restart)
            RESTART_ADB=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Restart ADB server if requested
if [ "$RESTART_ADB" = true ]; then
    echo "Restarting ADB server..."
    adb kill-server
    adb start-server
    echo "ADB server restarted."
fi

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "ADB is not installed. Please install it first."
    exit 1
fi

# Get list of already connected devices
connected_devices=$(adb devices | grep -v "List" | awk '{print $1}')

# Check if the target device is already connected wirelessly
echo "Checking for existing wireless connections..."
PEER_LIST=$(nordvpn meshnet peer list)
PEER_BLOCK=$(echo "$PEER_LIST" | awk "/Hostname: $TARGET_HOSTNAME/{flag=1;next}/Hostname: /{flag=0}flag")

if [ -n "$PEER_BLOCK" ]; then
    STATUS=$(echo "$PEER_BLOCK" | grep "Status:" | awk '{print $2}')
    if [ "$STATUS" = "connected" ]; then
        meshnet_ip=$(echo "$PEER_BLOCK" | grep "IP:" | awk '{print $2}')
        if echo "$connected_devices" | grep -q "$meshnet_ip:5555"; then
            echo "Device is already connected wirelessly at $meshnet_ip:5555"
            exit 0
        fi
    fi
fi

# Check if a device is connected via USB
device=$(adb devices | awk 'NR>1 && $2=="device" && !/:/ {print $1}')
if [ -z "$device" ]; then
    echo "No USB-connected device found. Please connect your phone via USB."
    exit 1
fi
echo "Device found: $device"

# Enable TCP/IP mode on port 5555
adb tcpip 5555
echo "ADB TCP/IP mode enabled on port 5555."

# Try to get the device's IP address
ip_address=$(adb shell ip route | awk '{print $9}' | head -n 1)
if [ -z "$ip_address" ]; then
    echo "Could not automatically detect phone IP using ADB method."
    
    # Try to get IP from nordvpn meshnet directly
    echo "Trying to get IP from nordvpn meshnet..."
    
    PEER_LIST=$(nordvpn meshnet peer list)
    PEER_BLOCK=$(echo "$PEER_LIST" | awk "/Hostname: $TARGET_HOSTNAME/{flag=1;next}/Hostname: /{flag=0}flag")
    
    if [ -n "$PEER_BLOCK" ]; then
        STATUS=$(echo "$PEER_BLOCK" | grep "Status:" | awk '{print $2}')
        if [ "$STATUS" = "connected" ]; then
            ip_address=$(echo "$PEER_BLOCK" | grep "IP:" | awk '{print $2}')
            echo "Successfully got IP from nordvpn meshnet: $ip_address"
        else
            echo "Peer found but not connected."
        fi
    else
        echo "Peer not found in nordvpn meshnet."
    fi
    
    # If still empty, ask for manual input
    if [ -z "$ip_address" ]; then
        echo "Could not automatically detect phone IP. Please enter it manually:"
        read -p "Phone IP Address: " ip_address
    fi
fi

# Check if the device is already connected via the same IP
if echo "$connected_devices" | grep -q "$ip_address:5555"; then
    echo "Device with IP $ip_address is already connected. No need to reconnect."
    exit 0
fi

echo "Connecting to $ip_address..."
adb connect "$ip_address:5555"

# Check if connection was successful
if adb devices | grep -q "$ip_address:5555"; then
    echo "Connected successfully to $ip_address:5555!"
else
    echo "Failed to connect. Ensure the phone is on the same network and try again."
fi
