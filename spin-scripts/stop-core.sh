#!/usr/bin/env bash

# Function to print pretty plus signs that are of the same length as the message sent
function print_plus () {
    python -c "print('+'*len(\"$1\"))"
}

# Base folder for Spinnaker
SPINNAKER_DEV="$HOME/dev/spinnaker"
declare -A port=( ["deck"]="9000" ["clouddriver"]="7002" ["front50"]="8080" ["fiat"]="7003" ["gate"]="8084" ["orca"]="8083" )

for ms in clouddriver front50 deck fiat gate orca; do
    echo "Stopping $ms..."
    $SPINNAKER_DEV/scripts/$ms-stop.sh
    echo 
    sleep 1
    echo "Checking if clouddriver port is released..."
    echo "Port value is ${port[$ms]}"
    sudo lsof -t -i:${port[$ms]}
    echo "---"
    echo 
    sleep 1
done

echo
final_message="Core Spinnaker Microservices have been stopped!"
print_plus "$final_message"
echo $final_message
print_plus "$final_message"
echo

