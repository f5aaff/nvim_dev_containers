#!/bin/bash
ENV_PATH="$1"
if [ -z $ENV_PATH ];then
    ENV_PATH=./container_man.env
fi
source $ENV_PATH
case "$1" in
-h | --help)
    echo "Usage: $0 [-b|-s|-S|-c [path/to/.env](optional)]"
    echo "     [-h|--help] prints this message"
    echo "     [-b|--build] builds the container at the path given by DOCKER_PATH in the .env"
    echo "     [-s|--start] runs docker compose up on the container located under DOCKER_PATH"
    echo "     [-S|--stop] stops the container located under DOCKER_PATH"
    echo "     [-c|--connect] attempts to connect an nvim instance to the given container, provided the details are correct, taken from the .env as CONTAINER_NAME and PORT respectively."
    exit 0
    ;;
-b | --build)
    if [ "$OFFLINE" = true ]; then
        CMD="./util/getBins.sh"

        if [ -n "$PACKAGES" ]; then
            CMD="$CMD -i $PACKAGES"
        fi

        if [ -n "$PACKAGE_OUTPUT" ]; then
            CMD="$CMD -o $PACKAGE_OUTPUT"
        fi

        # Execute the command
        echo "Executing: $CMD"
        $CMD
    fi
    CMD="./package_nvim.sh"
    if [ -n "$DOCKER_PATH" ]; then
        CMD="$CMD -d $DOCKER_PATH"
    fi

    $CMD

    cd $DOCKER_PATH
    docker compose build
    ;;
-s | --start)
    if [ -z "$DOCKER_PATH" ]; then
        DOCKER_PATH=./docker
    fi
    cd $DOCKER_PATH
    docker compose up
    cd -
    ;;
-S | --stop)
    if [ -z "$DOCKER_PATH" ]; then
        DOCKER_PATH=./docker
    fi
    cd $DOCKER_PATH

    docker compose down

    cd -
    ;;
-c | --connect)
    if [[ -z "$CONTAINER_NAME" ]]; then
        CONTAINER_NAME="neovim_headless"
    fi

    if [[ -z "$PORT" ]]; then
        PORT=6666
    fi
    printf "\e[32m using $CONTAINER_NAME as the server with port $PORT...\n\e[0m"
    SERVER=$(docker exec $CONTAINER_NAME hostname -i)
    nvim --server $SERVER:$PORT --remote-ui
    ;;
*)
    echo "Invalid argument: $1" >&2
    $0 --help
    exit 1
    ;;
esac
