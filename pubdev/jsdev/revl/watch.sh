#!/bin/bash

cleanup() {
    local pids=$(jobs -pr)
    [ -n "$pids" ] && kill $pids 2>/dev/null
    exit
}

trap 'cleanup' EXIT SIGINT SIGTERM

if coffee --version; then
    while true; do
        coffee -w -m -o js .
        sleep 1
        echo "Relaunching coffeescript after temp file failure..."
    done
else
    echo "You must have coffee-script >= 1.11.1 installed. Try 'npm install --global coffee-script'"
    exit 1
fi
