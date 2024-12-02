#!/bin/bash

TMP_STORE=$(mktemp -d)

copy_with_progress(){
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

# Export the function for `find` to use
export -f convert_symlink

# Export the realpath utility (some systems may require this for compatibility)
export PATH

copy_with_progress  ~/.local/share/nvim/ $TMP_STORE/local_share
copy_with_progress  ~/.config/nvim/ $TMP_STORE/config_nvim



# Recursively find all symlinks and process them
find "$TMP_STORE" -type l -exec bash -c 'convert_symlink "$0"' {} \;

