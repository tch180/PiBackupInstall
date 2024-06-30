#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Display the menu
show_menu() {
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${WHITE}                INSTALL MENU                  ${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${GREEN}1. ${WHITE}Generate SSH Key${NC}"
    echo -e "${GREEN}2. ${WHITE}Add SSH Key to ssh-agent${NC}"
    echo -e "${GREEN}3. ${WHITE}Display SSH Public Key${NC}"
    echo -e "${GREEN}4. ${WHITE}Append ssh-agent startup commands to ~/.bashrc${NC}"
    echo -e "${GREEN}5. ${WHITE}Create Backup Script${NC}"
    echo -e "${GREEN}6. ${WHITE}Update .gitignore${NC}"
    echo -e "${GREEN}7. ${WHITE}Initialize Git Repository${NC}"
    echo -e "${GREEN}8. ${WHITE}Set up Cron Jobs for Automated Backups${NC}"
    echo -e "${GREEN}9. ${WHITE}Enable and Start Cron Service${NC}"
    echo -e "${GREEN}10. ${WHITE}Reboot the System${NC}"
    echo -e "${RED}0. ${WHITE}Exit${NC}"
    echo -e "${CYAN}==============================================${NC}"
}

# Function to prompt for user's email and generate an SSH key for GitHub authentication
generate_ssh_key() {
    read -p "Enter your email address: " github_email
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_rsa -C "$github_email"
}

# Function to start the ssh-agent and add the generated SSH key
add_ssh_key_to_agent() {
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/github_rsa
}

# Function to display the SSH public key and instruct the user to add it to their GitHub account
display_ssh_public_key() {
    cat ~/.ssh/github_rsa.pub
    echo "Copy the above SSH public key and add it to your GitHub account."
    echo "Follow these steps:"
    echo "1. Log in to your GitHub account."
    echo "2. Click on your profile picture in the top right corner and select 'Settings'."
    echo "3. In the left sidebar, click on 'SSH and GPG keys'."
    echo "4. Click 'New SSH key' and paste the copied key into the 'Key' field."
    echo "5. Give the key a title (e.g., 'Raspberry Pi SSH Key')."
    echo "6. Click 'Add SSH key' to save it."
}

# Function to append ssh-agent startup commands to ~/.bashrc for automatic agent startup
append_ssh_agent_to_bashrc() {
    echo "Appending ssh-agent startup commands to ~/.bashrc"
    echo -e "\n# Auto-start ssh-agent and add SSH key\neval \"\$(ssh-agent -s)\"\nssh-add ~/.ssh/github_rsa" >> ~/.bashrc
    echo "ssh-agent startup commands added to ~/.bashrc. They will take effect in the next session."
}

# Function to create the backup script
create_backup_script() {
    echo "Creating the backup.sh script..."
    cat <<'EOF' > ~/backup.sh
#!/bin/bash

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_rsa 

CONFIG_FILE="$HOME/backup.conf"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    # Configuration file does not exist, prompt the user for the source directory
    read -p "Enter the Source dir: " SOURCE_DIR
    # Save the source directory to the configuration file
    echo "SOURCE_DIR='$SOURCE_DIR'" > "$CONFIG_FILE"
else
    # Configuration file exists, source it to read the saved source directory
    source "$CONFIG_FILE"
fi

COMMIT_MESSAGE="Backup on $(date +'%Y-%m-%d %H:%M:%S')"
cd "$SOURCE_DIR" || exit 1

if [ ! -d ".git" ]; then
    git init
    git remote add origin "git@github.com:$GITHUB_USER/$GITHUB_REPO.git"
    git branch -M main
fi

git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
EOF
    chmod +x ~/backup.sh
    echo "Backup script created and made executable."
}

# Function to create or append to .gitignore, dynamically adding directories with a .git directory
update_gitignore() {
    echo "Creating or updating .gitignore file"
    GITIGNORE_FILE=".gitignore"
    {
    echo "*.ssh/"
    echo "*.pub"
    echo "*.key"
    echo "known_hosts"
    echo ".gitignore"
    # Find and ignore directories containing a .git folder
    find "$SOURCE_DIR" -type d -name ".git" | while IFS= read -r git_dir; do
        if [ "$git_dir" != "$SOURCE_DIR/.git" ]; then
            relative_path=$(echo "$git_dir" | sed "s|$SOURCE_DIR/||" | sed 's|/.git||')
            echo "$relative_path/"
        fi
    done
    echo "/boot/"
    echo "/dev/"
    # Add other patterns here
    } > "$GITIGNORE_FILE"
    echo ".gitignore file created/updated."
}

# Function to check and initialize Git in the source directory if necessary
initialize_git_repository() {
    if [ ! -d "$SOURCE_DIR/.git" ]; then
        echo "Initializing a Git repository in $SOURCE_DIR"
        read -p "Enter your GitHub username: " GITHUB_USER
        read -p "Enter your GitHub repository name: " GITHUB_REPO
        cd "$SOURCE_DIR" || exit
        git init
        git remote add origin "git@github.com:$GITHUB_USER/$GITHUB_REPO.git"
        git branch -M main
    fi
}

# Function to set up cron jobs for automated backups
setup_cron_jobs() {
    echo "Setting up cron jobs for automated backups"
    (crontab -l 2>/dev/null; echo "0 12 * * 5 ~/backup.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 13 */3 * * ~/backup.sh") | crontab -
    echo "Cron jobs scheduled."
}

# Function to enable and start the cron service
enable_and_start_cron_service() {
    sudo systemctl enable cron.service && sudo systemctl start cron.service && echo "Cron service started successfully" || echo "Failed to start cron service"
}

# Function to reboot the system
reboot_system() {
    echo "Rebooting the system for changes to take full effect..."
    sudo reboot
}

# Main script
# Main script
while true; do
    show_menu
    read -p "Enter the number of the step you want to run: " choice
    case $choice in
        1) generate_ssh_key ;;
        2) add_ssh_key_to_agent ;;
        3) display_ssh_public_key ;;
        4) append_ssh_agent_to_bashrc ;;
        5) create_backup_script ;;
        6) update_gitignore ;;
        7) initialize_git_repository ;;
        8) setup_cron_jobs ;;
        9) enable_and_start_cron_service ;;
        10) reboot_system ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    read -p "Press [Enter] key to continue..."
done
