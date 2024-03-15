#!/bin/bash

# Prompt for user's email and generate an SSH key for GitHub authentication
read -p "Enter your email address: " github_email
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_rsa -C "$github_email"

# Start the ssh-agent and add the generated SSH key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_rsa

# Display the SSH public key and instruct the user to add it to their GitHub account
cat ~/.ssh/github_rsa.pub
echo "Copy the above SSH public key and add it to your GitHub account."
echo "Follow these steps:"
echo "1. Log in to your GitHub account."
echo "2. Click on your profile picture in the top right corner and select 'Settings'."
echo "3. In the left sidebar, click on 'SSH and GPG keys'."
echo "4. Click 'New SSH key' and paste the copied key into the 'Key' field."
echo "5. Give the key a title (e.g., 'Raspberry Pi SSH Key')."
echo "6. Click 'Add SSH key' to save it."


# Append ssh-agent startup commands to ~/.bashrc for automatic agent startup
echo "Appending ssh-agent startup commands to ~/.bashrc"
echo -e "\n# Auto-start ssh-agent and add SSH key\neval \"\$(ssh-agent -s)\"\nssh-add ~/.ssh/github_rsa" >> ~/.bashrc
echo "ssh-agent startup commands added to ~/.bashrc. They will take effect in the next session."

# Create the backup script
echo "Creating the backup.sh script"
cat <<'EOF' > ~/backup.sh
#!/bin/bash
read -p "Enter the Source dir: " SOURCE_DIR
COMMIT_MESSAGE="Backup on \$(date +'%Y-%m-%d %H:%M:%S')"
cd "\$SOURCE_DIR" || exit 1

if [ ! -d ".git" ]; then
    git init
    git remote add origin "git@github.com:\$GITHUB_USER/\$GITHUB_REPO.git"
    git branch -M main
fi

git add .
git commit -m "\$COMMIT_MESSAGE"
git push -u origin main
EOF
chmod +x ~/backup.sh
echo "Backup script created and made executable."

# Create or append to .gitignore, dynamically adding directories with a .git directory
echo "Creating or updating .gitignore file"
GITIGNORE_FILE=".gitignore"
{
echo ".ssh/"
echo "*.pub"
echo "*.key"
echo "known_hosts"
echo ".gitignore"
# Find and ignore directories containing a .git folder
find "$SOURCE_DIR" -type d -name ".git" | while read git_dir; do
    if [ "$git_dir" != "$SOURCE_DIR/.git" ]; then
        relative_path=\$(echo "\${git_dir}" | sed "s|\$SOURCE_DIR/||" | sed 's|/.git||')
        echo "\$relative_path/"
    fi
done
echo "/boot/"
echo "/dev/"
# Add other patterns here
} > "$GITIGNORE_FILE"
echo ".gitignore file created/updated."

# Check and initialize Git in the source directory if necessary
if [ ! -d "$SOURCE_DIR/.git" ]; then
    echo "Initializing a Git repository in $SOURCE_DIR"
    read -p "Enter your GitHub username: " GITHUB_USER
    read -p "Enter your GitHub repository name: " GITHUB_REPO
    cd "$SOURCE_DIR" || exit
    git init
    git remote add origin "git@github.com:$GITHUB_USER/$GITHUB_REPO.git"
    git branch -M main
fi

# Set up cron jobs for automated backups
echo "Setting up cron jobs for automated backups"
(crontab -l 2>/dev/null; echo "0 12 * * 5 ~/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 13 */3 * * ~/backup.sh") | crontab -
echo "Cron jobs scheduled."

# Enable and start the cron service, then reboot the system
sudo systemctl enable cron.service && sudo systemctl start cron.service && echo "Cron service started successfully" || echo "Failed to start cron service"
echo "Rebooting the system for changes to take full effect..."
sudo reboot
