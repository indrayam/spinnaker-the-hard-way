#!/bin/bash

# Function to print pretty plus signs that are of the same length as the message sent
function print_plus () {
    python -c "print('+'*len(\"$1\"))"
}

# Base folder for Spinnaker
SPINNAKER_DEV="$HOME/dev/spinnaker"

for ms in clouddriver front50 deck fiat gate orca; do
    echo
    echo "Starting $ms..."
    $SPINNAKER_DEV/scripts/$ms-start.sh
    echo "Sleeping for 20 secs to let $ms startup.."
    sleep 20
done

echo
final_message="Core Spinnaker Microservices have been started!"
print_plus "$final_message"
echo $final_message
print_plus "$final_message"
echo

