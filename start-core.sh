#!/bin/bash

echo "Starting clouddriver (for interacting with clouds)..."
~/dev/spinnaker/scripts/clouddriver-start.sh
echo 
echo "---"
sleep 30
echo "Starting front50 (for persisting stuff to gcs)..."
~/dev/spinnaker/scripts/front50-start.sh
echo 
echo "---"
sleep 30
echo "Starting deck (for ui)..."
~/dev/spinnaker/scripts/deck-start.sh
echo 
echo "---"
echo 
echo "Starting fiat (for authc/authz)..."
~/dev/spinnaker/scripts/fiat-start.sh
echo 
echo "---"
echo 
echo "Starting gate (for gating all api calls)..."
~/dev/spinnaker/scripts/gate-start.sh
echo 
echo "---"
echo 
echo "Starting orca (for orchestrating the pipelines)..."
~/dev/spinnaker/scripts/orca-start.sh
echo
echo "Core Spinnaker Microservices have been started!"
