#!/bin/bash
# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate IP address
validate_ip() {
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Prompt for IP Address
get_ip_address() {
    while true; do
        read -p "Enter IP Address: " IP_ADDRESS
        if validate_ip "$IP_ADDRESS"; then
            break
        else
            echo -e "${RED}Invalid IP address. Please try again.${NC}"
        fi
    done
}

# Prompt for Username
get_username() {
    read -p "Enter Username (default: ubuntu): " USERNAME
    USERNAME=${USERNAME:-ubuntu}
}

# Prompt for SSH Key Path
get_ssh_key() {
    while true; do
        read -p "Enter path to SSH key (default: ./Terraform/keys/terraform-ec2-key.pem): " SSH_KEY_PATH
        SSH_KEY_PATH=${SSH_KEY_PATH:-./Terraform/keys/terraform-ec2-key.pem}
        
        if [ ! -f "$SSH_KEY_PATH" ]; then
            echo -e "${RED}SSH key file not found. Please check the path.${NC}"
            continue
        fi
        
        # Set correct permissions for key file
        chmod 400 "$SSH_KEY_PATH"
        break
    done
}

# Main execution function
main() {
    # Clear the screen for clean input
    clear
    echo -e "${GREEN}Interactive SSH Connection Script${NC}"
    echo "----------------------------------------"
    echo -e "${YELLOW}Script will prompt for IP address, username, and key details${NC}"
    echo "Current working directory:"
    pwd
    echo "  "

    # Collect connection details
    get_ip_address
    get_username
    get_ssh_key

    # Confirm connection details
    echo -e "\n${YELLOW}Connection Details:${NC}"
    echo "IP Address: ${IP_ADDRESS}"
    echo "Username: ${USERNAME}"
    echo "SSH Key: ${SSH_KEY_PATH}"

    # Prompt for confirmation
    read -p "Confirm connection? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo -e "${RED}Connection aborted.${NC}"
        exit 1
    fi

    # Establish interactive SSH connection
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i "${SSH_KEY_PATH}" \
        "${USERNAME}@${IP_ADDRESS}"
}

# Run main function
main