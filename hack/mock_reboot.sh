#!/bin/bash

# Simulate a node reboot
node=$1
status_file="node_status_${node}.txt"

# Mark the node as down for a short period and then back up
echo "Node $node is down" > "$status_file"
sleep 5
echo "Node $node is up" > "$status_file"
