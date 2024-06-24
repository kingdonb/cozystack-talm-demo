#!/bin/bash

# Simulate ping response based on node status
node=$1
status_file="node_status_${node}.txt"

if [ ! -f "$status_file" ]; then
    echo "Node $node is up" > "$status_file"
fi

if grep -q "is down" "$status_file"; then
    exit 1  # Simulate ping failure
else
    exit 0  # Simulate ping success
fi
