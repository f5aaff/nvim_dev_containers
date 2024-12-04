##!/bin/bash

# Default .env path
DEFAULT_ENV_PATH="./container_man.env"

# Function to display help
function show_help {
    cat <<EOF
Usage: $0 [options]
Options:
  -h, --help          Prints this message
  -b, --build         Builds the container using DOCKER_PATH from .env
  -s, --start         Runs 'docker compose up' on the container under DOCKER_PATH
      --silent(optional) starts silently as a background process, redirects all output to /dev/null
  -S, --stop          Stops the container located under DOCKER_PATH
  -c, --connect       Connects an nvim instance to the container using CONTAINER_NAME and PORT from .env
  \$ENV_PATH provide the path to the env path you wish to use, otherwise $DEFAULT_ENV_PATH will be used.
EOF
}

# Ensure the .env file exists before sourcing
if [[ -n "$ENV_PATH" && -f "$ENV_PATH" ]]; then
    echo "using .env: $ENV_PATH"
    source "$ENV_PATH"
elif [[ -n "$ENV_PATH" ]]; then
    echo "Environment file not found: $ENV_PATH, using default: $DEFAULT_ENV_PATH"
    ENV_PATH=$DEFAULT_ENV_PATH
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

    case "$2" in
    --silent)
        docker compose up -d >/dev/null 2>&1 &
        ;;
    *)
        docker compose up -d
        ;;
    esac
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
