#!/bin/bash

S3_SAVE_BUCKET=$1
FACTORIO_USERNAME=$2
FACTORIO_AUTH_TOKEN=$3

# Set the target directory
TARGET_DIR="/opt"
FACTORIO_USER="factorio"
FACTORIO_DIR="$TARGET_DIR/factorio"  # Directory for Factorio installation
SERVER_SETTINGS_FILE="$FACTORIO_DIR/data/server-settings.json"
SERVER_MODS_FILE="$FACTORIO_DIR/mods/mod-list.json"

# Change to the target directory
cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }

# Clone the GitHub repository
git clone https://github.com/ThompsonDanielK/factorio-init.git

# Check if the cloning was successful
if [[ $? -ne 0 ]]; then
    echo "Failed to clone the repository."
    exit 1
fi

# Rename or copy the config.example to config
if [[ -f "factorio-init/config.example" ]]; then
    mv "factorio-init/config.example" "factorio-init/config"
    echo "Renamed config.example to config. Please modify the values in the config file."
else
    echo "config.example file not found. Please check the cloned repository."
    exit 1
fi

# Remove the extras directory if it exists
if [[ -d "factorio-init/extras" ]]; then
    rm -rf "factorio-init/extras"
    echo "Removed the extras directory."
else
    echo "Extras directory not found. Nothing to remove."
fi

# Add Factorio user
echo "Adding Factorio user..."
if ! id -u "$FACTORIO_USER" &>/dev/null; then
    sudo useradd -r -d "$TARGET_DIR" -s /sbin/nologin "$FACTORIO_USER"
    if [ $? -ne 0 ]; then
        echo "Failed to add Factorio user. Exiting."
        exit 1
    fi
else
    echo "User '$FACTORIO_USER' already exists."
fi

# Create the factorio directory if it doesn't exist in /opt
if [[ ! -d "$FACTORIO_DIR" ]]; then
    echo "Creating Factorio directory at $FACTORIO_DIR..."
    sudo mkdir "$FACTORIO_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create Factorio directory. Exiting."
        exit 1
    fi
fi

# Set ownership and permissions for the factorio-init directory
echo "Setting permissions for Factorio init directory..."
sudo chown -R "$FACTORIO_USER:$FACTORIO_USER" "$TARGET_DIR/factorio-init"
if [ $? -ne 0 ]; then
    echo "Failed to change ownership of factorio-init. Exiting."
    exit 1
fi

# Set permissions for the factorio-init directory
sudo chmod -R u+rwX "$TARGET_DIR/factorio-init"  # User can read, write, and execute directories
sudo chmod -R g+rwX "$TARGET_DIR/factorio-init"  # Group can read, write, and execute directories

# Set ownership and permissions for the factorio directory in /opt
echo "Setting permissions for the Factorio directory..."
sudo chown -R "$FACTORIO_USER:$FACTORIO_USER" "$FACTORIO_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to change ownership of factorio directory. Exiting."
    exit 1
fi

sudo chmod -R u+rwX "$FACTORIO_DIR"  # User can read, write, and execute directories
sudo chmod -R g+rwX "$FACTORIO_DIR"  # Group can read, write, and execute directories

# First-run installation check
echo "Checking if Factorio is installed..."
if [[ ! -f "$FACTORIO_DIR/config/config.ini" ]]; then
    echo "Factorio not found. Running first-time installation..."
    sudo -u "$FACTORIO_USER" "$TARGET_DIR/factorio-init/factorio" install
    if [ $? -ne 0 ]; then
        echo "Failed to install Factorio. Exiting."
        exit 1
    fi
    echo "Factorio installation complete."

# Create server settings file after installation
echo "Creating server settings file..."
cat <<EOF | sudo -u "$FACTORIO_USER" tee "$SERVER_SETTINGS_FILE" > /dev/null
{
    "name": "Dan's Dark n Dirty Pit",
    "description": "A place to get dark n dirty n build things",
    "tags": [],
    
    "_comment_max_players": "Maximum number of players allowed, admins can join even a full server. 0 means unlimited.",
    "max_players": 6,

    "_comment_visibility": [
        "public: Game will be published on the official Factorio matching server",
        "lan: Game will be broadcast on LAN"
    ],
    "visibility": {
        "public": true,  
        "lan": false       
    },

    "_comment_credentials": "Your factorio.com login credentials. Required for games with visibility public",
    "username": "$FACTORIO_USERNAME",
    "password": "",

    "_comment_token": "Authentication token. May be used instead of 'password' above.",
    "token": "$FACTORIO_AUTH_TOKEN",

    "game_password": "I<3Dan",

    "_comment_require_user_verification": "When set to true, the server will only allow clients that have a valid Factorio.com account",
    "require_user_verification": true,

    "_comment_max_upload_in_kilobytes_per_second": "optional, default value is 0. 0 means unlimited.",
    "max_upload_in_kilobytes_per_second": 0,

    "_comment_max_upload_slots": "optional, default value is 5. 0 means unlimited.",
    "max_upload_slots": 5,

    "_comment_minimum_latency_in_ticks": "optional one tick is 16ms in default speed, default value is 0. 0 means no minimum.",
    "minimum_latency_in_ticks": 0,

    "_comment_max_heartbeats_per_second": "Network tick rate. Maximum rate game updates packets are sent at before bundling them together. Minimum value is 6, maximum value is 240.",
    "max_heartbeats_per_second": 60,

    "_comment_ignore_player_limit_for_returning_players": "Players that played on this map already can join even when the max player limit was reached.",
    "ignore_player_limit_for_returning_players": false,

    "_comment_allow_commands": "possible values are, true, false and admins-only",
    "allow_commands": "admins-only",

    "_comment_autosave_interval": "Autosave interval in minutes",
    "autosave_interval": 10,

    "_comment_autosave_slots": "server autosave slots, it is cycled through when the server autosaves.",
    "autosave_slots": 5,

    "_comment_afk_autokick_interval": "How many minutes until someone is kicked when doing nothing, 0 for never.",
    "afk_autokick_interval": 0,

    "_comment_auto_pause": "Whether should the server be paused when no players are present.",
    "auto_pause": true,

    "_comment_auto_pause_when_players_connect": "Whether should the server be paused when someone is connecting to the server.",
    "auto_pause_when_players_connect": false
}
EOF
echo "Server settings file created."

# Create server settings file after installation
echo "Creating server settings file..."
cat <<EOF | sudo -u "$FACTORIO_USER" tee "$SERVER_MODS_FILE" > /dev/null
{
  "mods":
  [

    {
      "name": "base",
      "enabled": true
    },

    {
      "name": "elevated-rails",
      "enabled": true
    },

    {
      "name": "quality",
      "enabled": true
    },

    {
      "name": "space-age",
      "enabled": true
    }
  ]
}
EOF
echo "Server mod file created."

# Check if there are any files in the S3 bucket
if sudo -u $FACTORIO_USER /usr/local/bin/aws s3 ls s3://$S3_SAVE_BUCKET/ | grep -q '.'
then
    # Only delete local files if S3 bucket is not empty
    sudo -u $FACTORIO_USER rm -rf /opt/factorio/saves/*

    # Copy files from S3 to the local saves directory
    sudo -u $FACTORIO_USER /usr/local/bin/aws s3 cp s3://$S3_SAVE_BUCKET /opt/factorio/saves --recursive
else
    echo "No files found in S3 bucket. Skipping local deletion and sync."
fi

# Set up a cron job to sync files to S3 every 5 minutes
sudo -u $FACTORIO_USER bash -c '(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/aws s3 sync /opt/factorio/saves s3://$S3_SAVE_BUCKET --exclude \"server-save.zip\"") | crontab -'

else
    echo "Factorio already installed. Skipping installation step."
fi

# Enable auto shutdown for Factorio
cat << 'EOF' | sudo tee /home/ubuntu/auto-shutdown.sh
#!/bin/sh

shutdownIdleMinutes=10
idleCheckFrequencySeconds=1

isIdle=0
while [ $isIdle -le 0 ]; do
    isIdle=1
    iterations=$((60 / $idleCheckFrequencySeconds * shutdownIdleMinutes))
    while [ $iterations -gt 0 ]; do
        sleep $idleCheckFrequencySeconds
        connectionBytes=$(ss -lu | grep 34197 | awk '{s+=$2} END {print s}')
        if [ ! -z "$connectionBytes" ] && [ "$connectionBytes" -gt 0 ]; then
            isIdle=0
        fi
        if [ $isIdle -le 0 ] && [ $((iterations % 21)) -eq 0 ]; then
           echo "Activity detected, resetting shutdown timer to $shutdownIdleMinutes minutes."
           break
        fi
        iterations=$((iterations - 1))
    done
done

echo "No activity detected for $shutdownIdleMinutes minutes, shutting down."
sudo shutdown -h now
EOF

# Make auto-shutdown script executable
sudo chmod +x /home/ubuntu/auto-shutdown.sh
sudo chown ubuntu:ubuntu /home/ubuntu/auto-shutdown.sh

# Create systemd service for auto shutdown
cat << 'EOF' | sudo tee /etc/systemd/system/auto-shutdown.service
[Unit]
Description=Auto shutdown if no one is playing Factorio
After=syslog.target network.target nss-lookup.target network-online.target

[Service]
ExecStart=/home/ubuntu/auto-shutdown.sh
User=ubuntu
Group=ubuntu
StandardOutput=journal
Restart=on-failure
KillSignal=SIGINT
WorkingDirectory=/home/ubuntu

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the auto shutdown service
sudo systemctl enable auto-shutdown
sudo systemctl start auto-shutdown

# Add cron job to run update and start-server at system startup
CRON_JOB="@reboot sudo -u $FACTORIO_USER $TARGET_DIR/factorio-init/factorio update && sudo -u $FACTORIO_USER $TARGET_DIR/factorio-init/factorio start >> /var/log/factorio-update-start.log 2>&1"

# Check if the cron job already exists
if ! sudo crontab -l | grep -q "$CRON_JOB"; then
    (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
    echo "Cron job added to update and start Factorio server on system reboot."
else
    echo "Cron job already exists. Skipping addition."
fi

echo "Setup completed successfully."

sudo -u $FACTORIO_USER $TARGET_DIR/factorio-init/factorio update
sudo -u $FACTORIO_USER $TARGET_DIR/factorio-init/factorio start

echo "Factorio Service Started"
