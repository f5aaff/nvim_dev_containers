#!/bin/bash
case "$1" in
  -h|--help)
    echo "Usage: $0 [-h|--help]"
    exit 0
    ;;
  -b|--build)
    ./package_nvim.sh
    cd docker ; docker compose build
    ;;
  -s|--start)
      cd docker ; docker compose up
      ;;
  -S|--stop)
      cd docker ; docker compose down
      ;;
  -c|--connect)
      CONTAINER_NAME=$2
      PORT=$3
      if [[ -z "$CONTAINER_NAME" ]]; then
          printf "\e[31m please provide a container name, e.g nvim_headless\n\e[0m"
          exit 1
      fi

      if [[ -z "$PORT" ]]; then
          printf "\e[31m please provide a port, e.g 6666\n\e[0m"
          exit 1
      fi
      SERVER=$(docker exec $CONTAINER_NAME hostname -i)
      nvim --server $SERVER:$PORT --remote-ui
      ;;
  *)
    echo "Invalid argument: $1" >&2
    exit 1
    ;;
esac
