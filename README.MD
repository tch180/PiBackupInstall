## Raspberry Pi Backup and GitHub Setup Script

### This Bash script automates the process of generating an SSH key, creating a .gitignore file, setting up a Git repository, scheduling backup tasks, and restarting the system on your Raspberry Pi.

Instructions:

Follow these steps to use the script:

1. Open a terminal on your Raspberry Pi.

2. Download the script:

   $ `wget https://github.com/tch180/PiBackupInstall/archive/refs/tags/V0.8.zip`

   or for mac

   `curl -L0 https://github.com/tch180/PiBackupInstall/archive/refs/tags/V0.8.tar.gz `

3. unzip the file.
4. cd into the PiInstallBackup directory.
5. Make the script executable:

   ` chmod +x installBackup.sh`

6. Run the script:

   `$ ./installBackup.sh`

   The script will guide you through the setup process, asking for your GitHub email, source directory, and other configuration options.

7. After the script completes, it will have generated an SSH key, created a .gitignore file, set up a Git repository, scheduled backup tasks, and restarted the system.

Configuration:

- Github Username: You will be prompted to enter your Github Username.

- Email Address: You will be prompted to enter your GitHub email address.

- Source Directory: You will need to specify the source directory that you want to back up.

- Cron Jobs: The script sets up two cron jobs:

  - One to run the backup script every Friday at 12 noon.
  - Another to run tbackup script every 3 days at 1 PM.

- GitHub Repository: The script will prompt you for your GitHub username and repository name when initializing the Git repository.

Important Notes:

- Make sure to customize the SOURCE_DIR, BACKUP_DIR, GITHUB_USER, and GITHUB_REPO variables in the script according to your project requirements.

- Ensure that you have an active internet connection to access GitHub during the setup process.

- The script will automatically restart the Raspberry Pi after completing the setup.

- The repo must be set to private for this script to work correctly.

Contributions:

Contributions and improvements to this script are welcome. Feel free to create pull request.
