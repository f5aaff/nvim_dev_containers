#!/bin/bash

TMP_STORE=$(mktemp -d)

copy_with_progress() {
    SOURCE=$1
    TARGET=$2
    mkdir $TARGET
    tar cf - $SOURCE | pv -s $(du -sb $SOURCE | awk '{print $1}') | tar xf - -C $TARGET

}

# Function to convert absolute symlink to relative
convert_symlink() {
    local symlink_path="$1"
    local target_path
    local rel_path

    # Resolve the current symlink target
    target_path=$(readlink "$symlink_path")

    # Check if the symlink is absolute
    if [[ "$target_path" == /* ]]; then
        # Get the directory containing the symlink
        local symlink_dir
        symlink_dir=$(dirname "$symlink_path")

        # Compute the relative path from the symlink to the target
        rel_path=$(realpath --relative-to="$symlink_dir" "$target_path")

        # Replace the symlink with the relative one
        ln -sf "$rel_path" "$symlink_path"
        echo "Converted: $symlink_path -> $rel_path"
    fi
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
        echo "Updated: $symlink_path -> $new_target"
    fi
}

# Function to convert symlinks with /home/<user>/ to $HOME/
convert_symlink_home() {

    # Check if the directory is specified
    if [ -z "$1" ]; then
        echo "Usage: $0 <directory>"
        exit 1
    fi

    TARGET_DIR="$1"

    local symlink_path="$1"
    local target_path

    # Resolve the current symlink target
    target_path=$(readlink "$symlink_path")

    # Check if the target starts with /home/<user>/
    if [[ "$target_path" == /home/* ]]; then
        # Replace /home/<user>/ with $HOME/
        local new_target
        new_target="${target_path/#$HOME/$HOME}"

        # Replace the symlink with the updated one
        ln -sf "$new_target" "$symlink_path"
        echo "Updated: $symlink_path -> $new_target"
    fi
}


copy_with_progress ~/.local/share/nvim/ $TMP_STORE/local_share
printf "\e[32m copied ~/.local/share/nvim \n\e[0m"
copy_with_progress ~/.config/nvim/ $TMP_STORE/config_nvim
printf "\e[32m copied ~/.config/nvim \n\e[0m"
copy_with_progress ~/.local/share/bob/ $TMP_STORE/local_share_bob
printf "\e[32m copied ~/.local/share/bob/ \n\e[0m"


export -f convert_symlink_to_home_env

# Export the realpath utility (some systems may require this for compatibility)
export PATH

# Recursively find all symlinks and process them
 find "$TMP_STORE" -type l -exec bash -c 'convert_symlink_to_home_env "$0"' {} \;

tar -cvf nvim_$(date +%d-%m-%y_%H-%M-%S).tar $TMP_STORE


# install script, not written since the packaging isn't done
INSTALL_SCRIPT="$TMP_STORE/install_nvim.sh"

# Use `cat` to write the content of the script into the file
cat << 'EOF' > "$INSTALL_SCRIPT"
#!/bin/bash

#unpacking here?

EOF

# Make the generated script executable
chmod +x "$INSTALL_SCRIPT"

# Export the function for `find` to use
export -f convert_symlink_home

# Export the function for `find` to use
export -f convert_symlink

# Export the realpath utility (some systems may require this for compatibility)
export PATH

# Recursively find all symlinks and process them
# find "$TMP_STORE" -type l -exec bash -c 'convert_symlink_home "$0"' {} \;

