#!/bin/bash

echo "Stopping deck (for ui)..."
~/dev/spinnaker/scripts/deck-stop.sh
echo 
echo "---"
echo 
echo "Stopping echo (for emails and other notifications)..."
~/dev/spinnaker/scripts/echo-stop.sh
echo 
echo "---"
echo 
echo "Stopping clouddriver (for interacting with clouds)..."
~/dev/spinnaker/scripts/clouddriver-stop.sh
echo 
echo "---"
echo 
echo "Stopping front50 (for persisting stuff to gcs)..."
~/dev/spinnaker/scripts/front50-stop.sh
echo 
echo "---"
echo 
echo "Stopping fiat (for authc/authz)..."
~/dev/spinnaker/scripts/fiat-stop.sh
echo 
echo "---"
echo 
echo "Stopping gate (for gating all api calls)..."
~/dev/spinnaker/scripts/gate-stop.sh
echo 
echo "---"
echo 
echo "Stopping igor (for interactions with other cd tools)..."
~/dev/spinnaker/scripts/igor-stop.sh
echo 
echo "---"
echo 
echo "Stopping kayenta (for automated canary analysis)..."
~/dev/spinnaker/scripts/kayenta-stop.sh
echo 
echo "---"
echo 
echo "Starting orca (for orchestrating the pipelines)..."
~/dev/spinnaker/scripts/orca-stop.sh
echo 
echo "---"
echo 
echo "Stopping rosco (for baking vms)..."
~/dev/spinnaker/scripts/rosco-stop.sh
echo 
echo "All Spinnaker Microservices, minus Halyard, is stopped!"
