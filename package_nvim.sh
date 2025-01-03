#!/bin/bash

TMP_STORE="nvim_deps"
DOCKER_PATH=./docker

case "$1" in
-h | --help)
    echo "usage: $0 [-d /path/to/docker/files]"
    echo "-d|--docker-path : path pointing to docker files, e.g ./docker."
    exit 0
    # Display help or perform related action
    ;;
-d | --docker-path)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        DOCKER_PATH=$2
        shift # Shift past the argument
    else
        DOCKER_PATH=./docker # Set DOCKER_PATH to an empty string if no argument is given
    fi
    ;;
esac

# traps interrupts so it cleans up after itself
trap 'cleanup_and_exit' INT TERM KILL

function cleanup_and_exit() {
    echo "Exiting..."
    rm -rf $TMP_STORE >/dev/null
    rm -rf $TMP_STORE.tar >/dev/null
    exit 0
}

copy_with_progress() {
    SOURCE=$1
    TARGET=$2
    mkdir -p "$TARGET"
    LAST_DIR=$(basename "$SOURCE")
    tar cf - -C "$(dirname "$SOURCE")" "$LAST_DIR" | pv -s $(du -sb "$SOURCE" | awk '{print $1}') | tar xf - -C "$TARGET"
}

tar_with_progress() {
    SOURCE=$2
    ARCHIVE=$1
    touch $ARCHIVE
    if [[ -z "$SOURCE" || -z "$ARCHIVE" ]]; then
        echo "Usage: create_tar_with_progress <source> <archive>"
        return 1
    fi

    if [[ ! -d "$SOURCE" && ! -f "$SOURCE" ]]; then
        echo "Error: Source '$SOURCE' does not exist."
        return 1
    fi

    # Calculate the total size of the source
    TOTAL_SIZE=$(du -sb "$SOURCE" | awk '{print $1}')

    # Create tar archive with progress
    tar cf - "$SOURCE" | pv -s "$TOTAL_SIZE" >"$ARCHIVE"
}

#converts to explicitly the HOME variable, not the expanded value.
convert_symlink_to_home_env() {
    local symlink_path="$1"
    local target_path

    # Resolve the current symlink target
    target_path=$(readlink "$symlink_path")

    # Check if the target starts with /home/<user>
    if [[ "$target_path" == "$HOME/"* ]]; then
        # Replace the expanded $HOME with the literal $HOME
        local new_target="\$HOME${target_path#$HOME}"

        # Replace the symlink with the updated one
        ln -sf "$new_target" "$symlink_path"
    fi
}

if [[ -z "$(which pv)" ]]; then
    printf "\e[31m cannot find pv binary, please install pv and run this again.\n\e[0m"
    exit 1
fi

if [[ -z "$(which tar)" ]]; then
    printf "\e[31m cannot find tar binary, please install tar and run this again.\n\e[0m"
    exit 1
fi

mkdir $TMP_STORE

printf "\e[32m copying files... \n\e[0m"
# copy the relevent nvim files from their respective locations, to locations in the install tarball
copy_with_progress ~/.local/share/nvim/ $TMP_STORE/local_share
printf "\e[32m \tcopied ~/.local/share/nvim \n\e[0m"

copy_with_progress ~/.config/nvim/ $TMP_STORE/config_nvim
printf "\e[32m \tcopied ~/.config/nvim \n\e[0m"

if [[ -z "$(which bob)" ]]; then
    printf "\e[31m bob not installed, looking for nvim locally...\n\e[0m"
    if [[ -z "$(which nvim)" ]]; then
        printf "\e [31m nvim not installed locally, please install nvim.\n\e[0m"
        exit 1

    else

        printf "\e[32m nvim binary found locally, copying...\n\e[0m"
        nvim_bin=$(which nvim)
        cp nvim_bin $TMP_STORE/.local_share_bob/bob/nvim-bin/
    fi
else

    copy_with_progress ~/.local/share/bob/ $TMP_STORE/local_share_bob
    printf "\e[32m \tcopied ~/.local/share/bob/ \n\e[0m"

fi

# export the function for find to use
export -f convert_symlink_to_home_env

# Export the realpath utility (some systems may require this for compatibility)
export PATH

printf "\e[32m augmenting symlinks... \n\e[0m"
# Recursively find all symlinks and process them, replacing the full PATH
# in the link, with a path containing the unexpanded $HOME var
find "$TMP_STORE" -type l -exec bash -c 'convert_symlink_to_home_env "$0"' {} \;

chmod ugo+rw $TMP_STORE
# install script, not written since the packaging isn't done
INSTALL_SCRIPT="$TMP_STORE/install_nvim.sh"

# Use `cat` to write the content of the script into the file
cat <<'EOF' >"$INSTALL_SCRIPT"
#!/bin/bash

TARGET_USER=$1
if [[ -z "TARGET_USER" ]]; then
    TARGET_USER=$USER
fi

copy_with_progress() {
    SOURCE=$1
    TARGET=$2
    mkdir -p "$TARGET"
    LAST_DIR=$(basename "$SOURCE")
    tar cf - -C "$(dirname "$SOURCE")" "$LAST_DIR" | pv -s $(du -sb "$SOURCE" | awk '{print $1}') | tar xf - -C "$TARGET"
}

if [[ -z "$(which pv)" ]]; then
    printf "\e[31m cannot find pv binary, please install pv and run this again.\n\e[0m"
    exit 1
fi

if [[ -z "$(which tar)" ]]; then
    printf "\e[31m cannot find tar binary, please install tar and run this again.\n\e[0m"
    exit 1
fi

chmod -R ugo+rwx /nvim_deps
NVIM_UID=$(id -u nvim_user)
NVIM_GID=$(id -g nvim_user)
chown -R nvim_user /nvim_deps
chown -R $NVIM_UID:$NVIM_GID /nvim_deps
copy_with_progress ./local_share/nvim /home/$TARGET_USER/.local/share/
printf "\e[32m copied ~/.local/share/nvim \n\e[0m"

copy_with_progress ./local_share_bob/bob /home/$TARGET_USER/.local/share/
printf "\e[32m copied ~/.local/share/bob/ \n\e[0m"

copy_with_progress ./config_nvim/nvim /home/$TARGET_USER/.config/
printf "\e[32m copied ~/.config/nvim \n\e[0m"



EOF

# Make the generated script executable
chmod +x "$INSTALL_SCRIPT"

printf "\e[32m archiving files... \n\e[0m"
tar_with_progress $TMP_STORE.tar $TMP_STORE

printf "\e[32m copying archive into docker context... \n\e[0m"
pv $TMP_STORE.tar >$DOCKER_PATH/nvim_deps.tar
rm -rf $TMP_STORE
