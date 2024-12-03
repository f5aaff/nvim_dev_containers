#!/bin/bash
USER_IN=""
OUTPUT=./

# Parse command-line flags
while getopts "i:o:" flag; do
    case "${flag}" in
    i) # Enable verbose mode
        USER_IN="${OPTARG}"
        ;;
    o) # Set output file
        OUTPUT="${OPTARG}"
        ;;
    *) # Handle invalid flags
        echo "invalid flags"
        echo "Usage: $0 [-i a,b,c,d] [-o output_file]"
        exit 1
        ;;
    esac
done

if [[ -z "$USER_IN" ]]; then

    echo "Usage: $0 [-i a,b,c,d] [-o output_file]"
    exit 1
fi
# Split the string into an array
IFS=',' read -r -a array <<<"$USER_IN"

mkdir -p $OUTPUT &>/dev/null
# Iterate over the array and print each item
for i in "${array[@]}"; do
    LOC="$(command which $i)"
    cp $LOC $OUTPUT/

    echo "copied $(basename $LOC) to $OUTPUT"
done
