# Telegram Bot System Control

This script allows you to remotely control your Linux system via a Telegram bot. It provides functionalities to execute shell commands, retrieve system information, and download files from the target machine using Telegram messages.

## Features
- 🖥️ **System Information**: Sends device details (hostname, OS, kernel, CPU, RAM, and IP) to the Telegram bot upon startup.
- 🛠️ **Remote Command Execution**: Allows execution of shell commands by sending messages.
- 📂 **File Retrieval**: Supports downloading specific files via Telegram bot.
- 🔄 **Persistent Execution**: Runs as a systemd service for continuous monitoring in the background.

## Installation
1. Clone the repository and navigate to the script directory:
   ```bash
   git clone https://github.com/oscarmine/sysmnt.git
   cd sysmnt
   ```
2. Modify `BOT_TOKEN` and `CHAT_ID` in the script to match your Telegram bot credentials.
3. Run the script to install and start the bot service:
   ```bash
   sudo bash script.sh
   ```

## Usage
- **Execute commands**: Send any shell command (e.g., `whoami`, `ls -la`) to the bot, and it will return the output.
- **Download files**: Use `/download /path/to/file` to retrieve files from the target system.

## Video Tutorial
Youtube: https://youtu.be/i45yAoPI4c8?si=Z5MtSuYfYvUxMo1z

## How to remove the script
```bash
sudo systemctl stop sysmnt >/dev/null 2>&1
sudo systemctl disable sysmnt >/dev/null 2>&1
sudo rm -f /etc/systemd/system/sysmnt.service
sudo rm -f /usr/share/.sysmnt.sh
sudo systemctl daemon-reload >/dev/null 2>&1
```

## Security Notice
⚠️ **Use this script responsibly!** Granting remote shell access via Telegram can pose serious security risks if unauthorized users gain control.
