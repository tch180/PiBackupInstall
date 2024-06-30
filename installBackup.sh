#!/bin/bash

# Set home directory and Git repository variables
HOME_DIR="$HOME"
GIT_REPO_DIR="$HOME_DIR/.git"

# Check if .git directory exists
if [ ! -d "$GIT_REPO_DIR" ]; then
  echo "Initializing Git repository in $HOME_DIR..."
  git init --bare "$GIT_REPO_DIR"
else
  echo "Git repository already exists in $HOME_DIR."
fi

# Find subdirectories with existing Git repositories 
git submodule foreach --quiet 'echo $path' > /tmp/git_subdirs

# Loop through subdirectories and add them to .gitignore 
while IFS= read -r subdir; do
  if [ ! -z "$subdir" ] && [ "$subdir" != ".git" ]; then
    grep -q "^$subdir\$" "$HOME_DIR/.gitignore" || echo "$subdir" >> "$HOME_DIR/.gitignore"
  fi
done < /tmp/git_subdirs

# Clean up temporary file 
rm /tmp/git_subdirs

echo "Done setting up Git in your home directory!"

echo ""
echo "**Important Security Notice:**"
echo "Automating SSH key generation is a security risk! It's highly recommended to generate SSH keys manually for better control."

echo ""
# Commented-out line for automated key generation (not recommended)
echo "Generating SSH key pair..."
ssh-keygen -t rsa -b 2048 -N "" -f "$HOME_DIR/.ssh/id_rsa"


echo ""
echo "Once you've generated your keys, you'll need to add the public key to your GitHub account."
echo "Copy the above SSH public key and add it to your GitHub account."
echo "Follow these steps:"
echo "1. Log in to your GitHub account."
echo "2. Click on your profile picture in the top right corner and select 'Settings'."
echo "3. In the left sidebar, click on 'SSH and GPG keys'."
echo "4. Click 'New SSH key' and paste the copied key into the 'Key' field."
echo "5. Give the key a title (e.g., 'Raspberry Pi SSH Key')."
echo "6. Click 'Add SSH key' to save it."


# Enter the remote Git repository URL (replace with your actual URL)
echo ""
read -p "Enter the remote Git repository URL (including username): " remote_repo_url

# Backup script content
backup_script=$(cat <<'EOF'
#!/bin/bash

# Set home directory and Git repository variables
HOME_DIR="$HOME"
GIT_REPO_DIR="$HOME_DIR/.git"

# Timestamp for backup filename
timestamp=$(date +%Y-%m-%d_%H-%M-%S)

# Add all untracked files and directories (excluding .git) to Git
git add -A --ignore-missing --force "$HOME_DIR"

# Commit changes with a descriptive message
git commit -m "Daily backup - $timestamp"

# Push changes to remote repository
git push -u origin main

echo "Backup completed successfully!"

EOF
)

# Check if 'git' command exists
if ! command -v git &> /dev/null; then
  echo "Error: 'git' command not found. Please install it for backup functionality."
  exit 1
fi

# Create a file named 'backup_to_github.sh' in the same directory
echo "$backup_script" > "$HOME_DIR/backup_to_github.sh"

# Make the backup script executable
chmod +x "$HOME_DIR/backup_to_github.sh"

# Daily cron job schedule
daily_cron_schedule="0 0 * * *"  # Every day at midnight

# Create cron job entry for daily backup
crontab -l > /tmp/cronjobs
echo "$daily_cron_schedule $HOME_DIR/backup_to_github.sh $remote_repo_url" >> /tmp/cronjobs
crontab /tmp/cronjobs
rm /tmp/git_subdirs

echo "Successfully added cron job for daily backups to GitHub."

echo ""
echo "**Important:**"
echo "* This script creates a backup script named 'backup_to_github.sh' in your home directory."
echo "* Make sure this script is executable (use 'chmod +x $HOME_DIR/backup_to_github.sh')"
echo "* This script creates a cron job that runs with your user permissions. Ensure your user has read access to the files being backed up."