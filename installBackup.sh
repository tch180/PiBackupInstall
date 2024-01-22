#!/bin/bash

# Ask the user for their email address
read -p "Enter your email address: " github_email 

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_rsa -C "$github_email"

# add the SSH key to the ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_rsa


# Display the public key
cat ~/.ssh/github_rsa.pub

echo "Copy the above SSH public key and add it to your GitHub account."
echo "Follow these steps:"
echo "1. Log in to your GitHub account."
echo "2. Click on your profile picture in the top right corner and select 'Settings'."
echo "3. In the left sidebar, click on 'SSH and GPG keys'."
echo "4. Click 'New SSH key' and paste the copied key into the 'Key' field."
echo "5. Give the key a title (e.g., 'Raspberry Pi SSH Key')."
echo "6. Click 'Add SSH key' to save it."

# Create the backup.sh script
echo "Creating the backup.sh script"
cat <<EOF > ~/backup.sh
#!/bin/bash

# Paths
SOURCE_DIR="/path/to/your/source/directory"
BACKUP_DIR="/path/to/your/backup/directory"

# Commit message
COMMIT_MESSAGE="Backup on \$(date +'%Y-%m-%d %H:%M:%S')"

# Change to the source directory
cd \$SOURCE_DIR || exit 1

# Create a backup archive
tar czf \$BACKUP_DIR/backup-\$(date +'%Y%m%d%H%M%S').tar.gz .

# Change to the backup directory
cd \$BACKUP_DIR || exit 1

# Initialize Git repository if it's not already initialized
if [ ! -d ".git" ]; then
    git init
    git remote add origin "git@github.com:\$GITHUB_USER/\$GITHUB_REPO.git"
    git branch -M main

fi

# Add and commit the backup
git add .
git commit -m "\$COMMIT_MESSAGE"

# Push the backup to GitHub
git push -u origin master
EOF

chmod +x ~/backup.sh

read -p "Enter your source directory: " SOURCE_DIR

# Create .gitignore file
echo "Creating .gitignore file"

# Define the content of the .gitignore file
cat <<EOF > .gitignore
# Ignore SSH keys and configuration files
.ssh/
*.pub
*.key
known_hosts
.gitignore

# Ignore system-specific directories
/boot/
/dev/
/media/
/mnt/
/proc/
/sys/
/tmp/

# Ignore package manager cache and installation files
/var/
/etc/
lib/modules/
*.img

# Ignore log files
*.log

# Ignore swap files
*~

# Ignore user-specific files and directories
/home/
/root/

# Ignore compiled code or binary files
*.o
*.a
*.out
*.bin

# Ignore project-specific files and directories (customize as needed)
/node_modules/
.DS_Store
*.swp
EOF

# Check if a Git repository exists in the source directory
if [ ! -d "$SOURCE_DIR/.git" ]; then
    echo "Initializing a Git repository in $SOURCE_DIR"
    read -p "Enter your GitHub username: " GITHUB_USER
    read -p "Enter your GitHub repository name: " GITHUB_REPO

    # Initialize Git repository
    cd "$SOURCE_DIR" || exit 1
    git init
    git remote add origin "git@github.com:$GITHUB_USER/$GITHUB_REPO.git"
    git branch -M main
fi

## create and add cron jobs

# Schedule the backup script every Friday at 12 noon
echo "Scheduling the backup script to run every Friday at 12 noon"
(crontab -l ; echo "0 12 * * 5 ~/backup.sh") | crontab -

# Schedule backup script to run every 3 days at 1 PM
echo "Scheduling the backup script to run every 3 days"
(crontab -l ; echo "0 13 */3 * * ~/backup.sh") | crontab -

# Enable and start cron service
sudo systemctl enable cron.service
sudo systemctl start cron.service

if [ $? -eq 0 ]; then
    echo "Cron service started successfully"
else
    echo "Cron service failed to start"
fi

# Restart the system
echo "Restarting the system..."
sudo reboot
