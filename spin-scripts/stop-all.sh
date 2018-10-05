#!/bin/bash

# Function to print pretty plus signs that are of the same length as the message sent
function print_plus () {
    python -c "print('+'*len(\"$1\"))"
}

# Base folder for Spinnaker
SPINNAKER_DEV="$HOME/dev/spinnaker"

for ms in deck gate fiat clouddriver orca kayenta front50 rosco igor echo; do
    echo "Stopping $ms..."
    #$SPINNAKER_DEV/scripts/$ms-stop.sh
    sleep 1
done

echo
final_message="All Spinnaker Microservices, minus Halyard, is stopped!"
print_plus "$final_message"
echo $final_message
print_plus "$final_message"
echo

