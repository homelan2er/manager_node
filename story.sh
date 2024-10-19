#!/bin/bash

# Color variables
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Default snapshot URLs
SNAPSHOT_STORY_URL="https://story.josephtran.co/Story_snapshot.lz4"
SNAPSHOT_GETH_URL="https://story.josephtran.co/Geth_snapshot.lz4"

# Function to print colored logs
color_log() {
    case $1 in
        "green") COLOR=$GREEN ;;
        "purple") COLOR=$PURPLE ;;
        "orange") COLOR=$ORANGE ;;
        *) COLOR=$NC ;;
    esac
    echo -e "${COLOR}$2${NC}"
}

# Function to check command status
check_cmd_status() {
    if [ $? -eq 0 ]; then
        color_log "green" "🎉 Success: $1"
    else
        color_log "purple" "😢 Error: $1"
        return 1
    fi
}

# Install Story node
install_story_node() {
    clear
    color_log "green" "🚀 Starting Story node installation..."
    if source <(curl -s https://story.josephtran.co/scripts/story-node-installer.sh); then
        color_log "green" "✔ Story node installation completed"
    else
        color_log "purple" "✖ Failed to install Story node"
    fi
    read -n 1 -s -r -p "🔑 Press any key to continue"
}

# Manage node
manage_node() {
    clear
    color_log "orange" "⚙ Managing node..."
    if source <(curl -s https://story.josephtran.co/scripts/story-manage-node.sh); then
        color_log "green" "✔ Node management completed"
    else
        color_log "purple" "✖ Failed to manage the node"
    fi
}

# Remove node
remove_node() {
    clear
    color_log "purple" "🧹 Starting node removal..."
    if source <(curl -s https://story.josephtran.co/scripts/story-remove-node.sh); then
        color_log "green" "✔ Node removed successfully"
    else
        color_log "purple" "✖ Failed to remove the node"
    fi
    read -n 1 -s -r -p "🔑 Press any key to continue"
}

# Check node status
check_node_status() {
    clear
    color_log "orange" "🔍 Checking node status..."
    CONFIG_FILE="$HOME/.story/story/config/config.toml"
    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(grep 'laddr = "tcp://' "$CONFIG_FILE" | grep -oP ':\K\d+')
        if [ -z "$PORT" ]; then
            echo "❓ RPC port not found in the config."
            return
        fi
    else
        echo "❓ Config file not found!"
        return
    fi
    echo "Current node status:"
    curl -s "localhost:$PORT/status" | jq
    read -n 1 -s -r -p "🔑 Press any key to continue"
}

# Check block synchronization
check_block_sync() {
    clear
    color_log "purple" "🔗 Checking block sync..."
    CONFIG_FILE="$HOME/.story/story/config/config.toml"

    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(grep 'laddr = "tcp://' "$CONFIG_FILE" | grep -oP ':\K\d+')
        if [ -z "$PORT" ]; then
            echo "❓ RPC port not found in the config."
            return
        fi
    else
        echo "❓ Config file not found!"
        return
    fi

    trap 'return' INT
    while true; do
        local_height=$(curl -s "localhost:$PORT/status" | jq -r '.result.sync_info.latest_block_height')
        network_height=$(curl -s https://rpc-story.josephtran.xyz/status | jq -r '.result.sync_info.latest_block_height')
        
        if [ -z "$local_height" ] || [ -z "$network_height" ]; then
            echo "⚠ Error: Unable to fetch block heights. Check your node and network connection."
            sleep 5
            continue
        fi
        
        blocks_left=$((network_height - local_height))
        
        echo -e "\033[1;38m🟢 Your node height:\033[0m \033[1;34m$local_height\033[0m | \033[1;35mNetwork height:\033[0m \033[1;36m$network_height\033[0m | \033[1;29mBlocks left:\033[0m \033[1;31m$blocks_left\033[0m"
        sleep 5
    done
}

# Check Geth logs
check_geth_logs() {
    clear
    color_log "green" "📝 Viewing Story-Geth logs..."
    sudo journalctl -u story-geth -f -o cat
}

# Check Story logs
check_story_logs() {
    clear
    color_log "orange" "📜 Viewing Story logs..."
    sudo journalctl -u story -f -o cat
}

# Download snapshot
download_snapshot() {
    clear
    color_log "purple" "⬇ Starting snapshot download..."
    if source <(curl -s https://story.josephtran.co/scripts/story-download-snapshot.sh); then
        color_log "green" "✔ Snapshot downloaded successfully"
    else
        color_log "purple" "✖ Failed to download snapshot"
    fi
    read -n 1 -s -r -p "🔑 Press any key to continue"
}

# Upgrade node
upgrade_node() {
    clear
    color_log "orange" "🔄 Upgrading node..."
    if source <(curl -s https://story.josephtran.co/scripts/story-node-upgrader.sh); then
        color_log "green" "✔ Node upgraded successfully"
    else
        color_log "purple" "✖ Failed to upgrade node"
    fi
    read -n 1 -s -r -p "🔑 Press any key to continue"
}

# Main menu
main_menu() {
    clear
    local options=(
        "🔧 Install Story node" 
        "⚙ Manage node" 
        "🔍 Check node status/sync" 
        "⬆ Upgrade node"  
        "⬇ Download latest snapshot" 
        "🗑 Remove node" 
        "🚪 Exit"
    )
    local current=$1

    color_log "green" "=== Story Node Manager v2.0 ==="
    echo "Select an option and press Enter:"
    echo ""

    for i in "${!options[@]}"; do
        if [ "$i" -eq "$current" ]; then
            echo -e "${PURPLE}> $((i+1)). ${options[$i]}${NC}"
        else
            echo "  $((i+1)). ${options[$i]}"
        fi
    done
}

# Main menu logic
run_main_menu() {
    local current=0
    local options=("Install" "Manage" "Status/Sync" "Upgrade" "Download Snapshot" "Remove" "Exit")

    while true; do
        main_menu $current
        read -s -n 1 key
        case $key in
            [1-7]) current=$((key-1)) ;;
            "") case $current in
                    0) install_story_node ;;
                    1) manage_node ;;
                    2) check_node_status ;;
                    3) upgrade_node ;;
                    4) download_snapshot ;;
                    5) remove_node ;;
                    6) exit ;;
                esac ;;
        esac
    done
}

# Run the main menu
run_main_menu
