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

# Where the BD_Sensor folder is located
BD_SENSOR_PATH="$(user_dir)/Bed_Distance_sensor/klipper"

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

install_bdsensor_extension(){
    info "Installing BD_Sensor extension to klipper..."

    # Check if BDsensor.py does not already exist as a symbolic link
    if [[ ! -L "$KLIPPER_PATH/klippy/plugins/BDsensor.py" ]]
    then
        # Create a symbolic link for BDsensor.py
        ln -s "$BD_SENSOR_PATH/BDsensor.py" "$KLIPPER_PATH/klippy/plugins/BDsensor.py"
    fi

    # Check if BD_sensor.c does not already exist as a symbolic link
    if [[ ! -L "$KLIPPER_PATH/src/BD_sensor.c" ]]
    then
        # Create a symbolic link for BD_sensor.c
        ln -s "$BD_SENSOR_PATH/BD_sensor.c" "$KLIPPER_PATH/src/BD_sensor.c"
    fi

    # Check if make_with_bdsensor.sh does not already exist as a symbolic link
    if [[ ! -L "$KLIPPER_PATH/make_with_bdsensor.sh" ]]
    then
        # Create a symbolic link for make_with_bdsensor.sh
        ln -s "$BD_SENSOR_PATH/make_with_bdsensor.sh" "$KLIPPER_PATH/make_with_bdsensor.sh"
    fi

    if ! grep -q "klippy/plugins/BDsensor.py" "$KLIPPER_PATH/.git/info/exclude"; then
        echo "klippy/plugins/BDsensor.py" >> "$KLIPPER_PATH/.git/info/exclude"
    fi
    if ! grep -q "src/BD_sensor.c" "$KLIPPER_PATH/.git/info/exclude"; then
        echo "src/BD_sensor.c" >> "$KLIPPER_PATH/.git/info/exclude"
    fi

    if ! grep -q "make_with_bdsensor.sh" "$KLIPPER_PATH/.git/info/exclude"; then
        echo "make_with_bdsensor.sh" >> "$KLIPPER_PATH/.git/info/exclude"
    fi
}

preflight_checks() {
    ensure_root
    is_klipper_installed
}

preflight_checks
install_hooks
install_bdsensor_extension