##!/bin/bash

# Default .env path
DEFAULT_ENV_PATH="./container_man.env"

# Function to display help
function show_help {
    cat << EOF
Usage: $0 [options]
Options:
  -h, --help          Prints this message
  -b, --build         Builds the container using DOCKER_PATH from .env
  -s, --start         Runs 'docker compose up' on the container under DOCKER_PATH
  -S, --stop          Stops the container located under DOCKER_PATH
  -c, --connect       Connects an nvim instance to the container using CONTAINER_NAME and PORT from .env
  [path/to/.env]      Optional: Specify the .env file path (default: $DEFAULT_ENV_PATH)
EOF
}

# Parse optional .env path if it's not a flag
if [[ "$1" != -* ]]; then
    ENV_PATH="$1"
    shift
else
    ENV_PATH="$DEFAULT_ENV_PATH"
fi

# Ensure the .env file exists before sourcing
if [[ -f "$ENV_PATH" ]]; then
    source "$ENV_PATH"
else
    echo "Environment file not found: $ENV_PATH"
    exit 1
fi

# Parse command-line arguments
case "$1" in
-h | --help)
    show_help
    ;;
-b | --build)
    # Offline build preparation
    if [[ "$OFFLINE" == "true" ]]; then
        CMD="./util/getBins.sh"
        [[ -n "$PACKAGES" ]] && CMD="$CMD -i $PACKAGES"
        [[ -n "$PACKAGE_OUTPUT" ]] && CMD="$CMD -o $PACKAGE_OUTPUT"
        echo "Executing: $CMD"
        $CMD
    fi

    # Build the container
    CMD="./package_nvim.sh"
    [[ -n "$DOCKER_PATH" ]] && CMD="$CMD -d $DOCKER_PATH"
    echo "Executing: $CMD"
    $CMD

    [[ -n "$DOCKER_PATH" ]] && cd "$DOCKER_PATH"
    docker compose build
    ;;
-s | --start)
    DOCKER_PATH="${DOCKER_PATH:-./docker}"
    cd "$DOCKER_PATH" || exit
    docker compose up
    ;;
-S | --stop)
    DOCKER_PATH="${DOCKER_PATH:-./docker}"
    cd "$DOCKER_PATH" || exit
    docker compose down
    ;;
-c | --connect)
    CONTAINER_NAME="${CONTAINER_NAME:-neovim_headless}"
    PORT="${PORT:-6666}"
    echo -e "\e[32mUsing $CONTAINER_NAME as the server with port $PORT...\e[0m"
    SERVER=$(docker exec "$CONTAINER_NAME" hostname -i)
    nvim --server "$SERVER:$PORT" --remote-ui
    ;;
*)
    echo "Invalid argument: $1" >&2
    show_help
    exit 1
    ;;
esac
