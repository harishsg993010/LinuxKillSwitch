#!/bin/bash

LIMIT=10737418240  # 10GB limit in bytes

# Function to retrieve the total data transfer for a specific IP address
get_ip_data_transfer() {
    local ip_address=$1
    local total_data_transfer=$(sudo iptables -nvx -L OUTPUT | awk -v ip="$ip_address" '$0 ~ ip {print $2}')
    echo "$total_data_transfer"
}

# Function to block an IP address using iptables
block_ip_address() {
    local ip_address=$1
    sudo iptables -A INPUT -s "$ip_address" -j DROP
    sudo iptables -A OUTPUT -d "$ip_address" -j DROP
}

# Main script logic
while true; do
    # Get the IP addresses with data transfer
    ip_addresses=$(sudo iptables -nvx -L OUTPUT | awk '{print $8}' | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}')

    # Iterate through each IP address
    for ip_address in $ip_addresses; do
        total_data_transfer=$(get_ip_data_transfer "$ip_address")

        # Check if the total data transfer exceeds the limit
        if [[ $total_data_transfer -gt $LIMIT ]]; then
            echo "IP address $ip_address has exceeded the data transfer limit. Blocking the IP address..."

            # Block the IP address using iptables
            block_ip_address "$ip_address"

            echo "IP address $ip_address blocked."
        fi
    done

    sleep 1
done
