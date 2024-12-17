#!/bin/bash

# Where this Script is located
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR"/utils.sh

# Where the Klipper folder is located
KLIPPER_PATH="$(user_dir)/klipper"

# Where the user Klipper config is located
KLIPPER_CONFIG_PATH="$(user_dir)/printer_data/config"

# Where to clone THE100-Configuration repository
THE100_CONFIG_PATH="$(user_dir)/THE100-Configuration"

# Where the Moonraker folder is located
MOONRAKER_PATH="$(user_dir)/moonraker"

# Branch from MSzturc/THE100-Configuration repo to use during install (default: main)
THE100_CONFIG_REPOSITORY="https://github.com/MSzturc/THE100-Configuration.git"

# Branch from MSzturc/THE100-Configuration repo to use during install (default: main)
THE100_CONFIG_BRANCH="main"

download_configuration() {
    
    if [ -d "$THE100_CONFIG_PATH" ]; then
        info "Configuration repository already found locally at $THE100_CONFIG_PATH. Skipping download."
    else
        info "Configuration repository does not exist at $THE100_CONFIG_PATH. Cloning repository..."
        if git clone --quiet --branch "$THE100_CONFIG_BRANCH" "$THE100_CONFIG_REPOSITORY" "$THE100_CONFIG_PATH"; then
            check "Successfully cloned configuration repository to $THE100_CONFIG_PATH."
        else
            error "Failed to clone configuration repository."
            exit 1
        fi
    fi
}

# This function sets up git hooks for THE100-Configuration, Klipper, and Moonraker.
# The post-merge hooks ensure that specific scripts are executed automatically
# after a 'git pull' or 'git merge' operation in each repository. We use it to reapply
# install scripts for different Klipper addons.
install_hooks()
{
    info "Installing git hooks..."

    # Check if the post-merge hook for THE100-Configuration does not already exist as a symbolic link
    if [[ ! -L "$THE100_CONFIG_PATH/.git/hooks/post-merge" ]]
    then
        # Create a symbolic link for the THE100-Configuration post-merge script
        ln -s "$SCRIPT_DIR/post-merge-configuration.sh" "$THE100_CONFIG_PATH/.git/hooks/post-merge"
        info "Post-merge hook set up for THE100-Configuration."
    fi

    # Check if the post-merge hook for klipper does not already exist as a symbolic link
    if [[ ! -L "$KLIPPER_PATH/.git/hooks/post-merge" ]]
    then
        # Create a symbolic link for klipper post-merge script
        ln -s "$SCRIPT_DIR/post-merge-klipper.sh" "$KLIPPER_PATH/.git/hooks/post-merge"
        info "Post-merge hook set up for klipper."
    fi

    # Check if the post-merge hook for moonraker does not already exist as a symbolic link
    if [[ ! -L "$MOONRAKER_PATH/.git/hooks/post-merge" ]]
    then
        # Create a symbolic link for moonraker post-merge script
        ln -s "$SCRIPT_DIR/post-merge-moonraker.sh" "$MOONRAKER_PATH/.git/hooks/post-merge"
        info "Post-merge hook set up for moonraker."
    fi
}

# This function checks if a 'logs' directory exists in the user's home directory.
# If it doesn't exist, the function creates the directory and sets its permissions to allow 
# read and write access for all users. Additionally, it creates an empty 'theos.log' file 
# in the directory with the same permissions.
install_logs() {

    # Path to the logs directory
    local logs_dir="$(user_dir)/logs"
    local log_file="$logs_dir/theos.log"

    # Check if the 'logs' folder exists
    if [ ! -d "$logs_dir" ]; then
        info "Creating folder: $logs_dir"
        mkdir "$logs_dir"
    else
        debug "Folder already exists: $logs_dir"
    fi

    # Set permissions: read and write for all users (folder and future files)
    chmod 777 "$logs_dir"
    info "Permissions for folder $logs_dir set: read and write for all users."

    # Check if the file 'theos.log' exists, otherwise create it
    if [ ! -f "$log_file" ]; then
        debug "Creating file: $log_file"
        touch "$log_file"
    else
        debug "File already exists: $log_file"
    fi

    # Set permissions: read and write for all users for the file
    chmod 666 "$log_file"
    info "Permissions for file $log_file set: read and write for all users."
}

setup_sudo_permissions() {
    info "Starting sudo permissions setup."

    # Check if the sudoers configuration file for "theos-githooks" already exists
    if [[ -e /etc/sudoers.d/030-theos-githooks ]]
    then
        debug "Found existing sudoers file: /etc/sudoers.d/030-theos-githooks. Removing it."
        sudo rm /etc/sudoers.d/030-theos-githooks
    else
        debug "No existing sudoers file found. Proceeding with setup."
    fi

    # Create a temporary file for the new sudoers configuration
    info "Creating temporary sudoers file at /tmp/030-theos-githooks."
    touch /tmp/030-theos-githooks

    # Write the new sudoers rules into the temporary file
    info "Writing new sudo rules to temporary file."
    cat > /tmp/030-theos-githooks << EOF
$(current_user) ALL=(ALL) NOPASSWD: $(user_dir)/THE100-Configuration/scripts/update-configuration.sh
$(current_user) ALL=(ALL) NOPASSWD: $(user_dir)/THE100-Configuration/scripts/update-klipper.sh
$(current_user) ALL=(ALL) NOPASSWD: $(user_dir)/THE100-Configuration/scripts/update-moonraker.sh
EOF

    # Set ownership of the temporary file to root
    debug "Changing ownership of /tmp/030-theos-githooks to root:root."
    sudo chown root:root /tmp/030-theos-githooks

    # Set permissions to read-only for the owner
    debug "Setting file permissions to 440 (read-only for root) on /tmp/030-theos-githooks."
    sudo chmod 440 /tmp/030-theos-githooks

    # Copy the temporary file to the sudoers directory
    info "Copying temporary file to /etc/sudoers.d/030-theos-githooks with preserved permissions."
    sudo cp --preserve=mode /tmp/030-theos-githooks /etc/sudoers.d/030-theos-githooks

    # Clean up: remove the temporary file
    debug "Removing temporary file: /tmp/030-theos-githooks."
    sudo rm /tmp/030-theos-githooks

    info "Sudo permissions setup completed successfully."
}

install_udev_rules()
{
  info "Updating THEOS Board device symlinks.."
  
  # Remove existing udev rules files in /etc/udev/rules.d/ 
  # All board-specific udev rule files in THE100-Configuration are prefixed with '98-'
  rm -f /etc/udev/rules.d/98-*.rules
  
  # Create symbolic links for the updated udev rules from the configuration directory
  # Source: THE100-Configuration/config/boards/*/*.rules
  # Destination: /etc/udev/rules.d/ (udev directory where rule files are loaded)
  # This ensures the system uses the latest board-specific udev rules for device management
  ln -s $(user_dir)/THE100-Configuration/config/boards/*/*.rules /etc/udev/rules.d/
}







preflight_checks() {
    ensure_not_root
    is_klipper_installed
}

preflight_checks
download_configuration
install_logs
install_hooks
setup_sudo_permissions
install_udev_rules