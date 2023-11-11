#!/bin/bash

# Function to display informational messages
function display_message() {
    echo "Info: $1"
}

# Function to display error messages and terminate the script
function display_error() {
    echo "Erro: $1"
    exit 1
}

# Check arguments
if [ "$#" -lt 1 ]; then
    display_error "Usage: $0 storage_type [remote_name] [config_is_local=true]"
fi

# Check storage type validity
STORAGE_TYPES=("drive" "onedrive")
if [[ " ${STORAGE_TYPES[*]} " != *" $1 "* ]]; then
    display_error "Invalid storage type. Choose between: ${STORAGE_TYPES[*]}"
fi

# Set default values
is_local=${3:-true}
remote_name=${2:-"default"}

# Create the configuration in Rclone
rclone config create "$remote_name" "$1" config_is_local "$is_local" || display_error "Failed to create configuration in Rclone."

# Configure and start systemd service
sudo cp ./Cloud-StorageStart.sh -r /bin || display_error "Failed to copy Cloud-StorageStart.sh."
sudo cp ./Cloud-Storage.service -r /etc/systemd/system/ || display_error "Failed to copy Cloud-Storage.service."

# Replace placeholders in scripts and services
sudo sed -i "s/default/$remote_name/g" /bin/Cloud-StorageStart.sh /etc/systemd/system/Cloud-Storage.service || display_error "Failed to replace placeholders."
sudo sed -i "s/Cloud/$remote_name/g" /etc/systemd/system/Cloud-Storage.service || display_error "Failed to replace placeholders."
sudo sed -i "s/UserName/$(whoami)/g" /etc/systemd/system/Cloud-Storage.service || display_error "Failed to replace placeholders."

# Rename service and create mount directory
sudo mv /bin/Cloud-StorageStart.sh /bin/$remote_name-StorageStart.sh || display_error "Failed to rename Cloud-StorageStart.sh."
sudo mv /etc/systemd/system/Cloud-Storage.service /etc/systemd/system/$remote_name-Storage.service || display_error "Failed to rename Cloud-Storage.service."
sudo mkdir -p /mnt/$remote_name || display_error "Failed to create mount directory."

# Check if the group already exists
if ! grep -q "^storage_users:" /etc/group; then
    sudo groupadd storage_users || display_error "Failed to create the storage_users group."
    display_message "Storage_users group created successfully."
fi

# Assign the directory to the group and set permissions
sudo chown :storage_users /mnt/$remote_name || display_error "Failed to assign permissions to the mount directory."
sudo chmod 775 /mnt/$remote_name || display_error "Failed to set permissions to the mount directory."

# Add users to group
sudo usermod -aG storage_users $(whoami) || display_error "Failed to add user to the storage_users group."

# Reload and enable systemd service
sudo systemctl daemon-reload || display_error "Failed to reload systemd."
sudo systemctl enable $remote_name-Storage.service || display_error "Failed to enable systemd service."
sudo systemctl start $remote_name-Storage.service || display_error "Failed to start systemd service."

display_message "Complete Rclone configuration for remote '$remote_name'!"
