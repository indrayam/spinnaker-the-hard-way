#!/bin/bash

echo "Stopping deck (for ui)..."
~/dev/spinnaker/scripts/deck-stop.sh
echo 
sleep 1
echo "Checking if deck port is released..."
sudo lsof -t -i:9000
echo "---"
echo 
echo "Stopping clouddriver (for interacting with clouds)..."
~/dev/spinnaker/scripts/clouddriver-stop.sh
echo 
sleep 1
echo "Checking if clouddriver port is released..."
sudo lsof -t -i:7002
echo "---"
echo 
echo "Stopping front50 (for persisting stuff to gcs)..."
~/dev/spinnaker/scripts/front50-stop.sh
echo 
sleep 1
echo "Checking if front50 port is released..."
sudo lsof -t -i:8080
echo "---"
echo 
echo "Stopping fiat (for authc/authz)..."
~/dev/spinnaker/scripts/fiat-stop.sh
echo 
sleep 1
echo "Checking if fiat port is released..."
sudo lsof -t -i:7003
echo "---"
echo 
echo "Stopping gate (for gating all api calls)..."
~/dev/spinnaker/scripts/gate-stop.sh
echo 
sleep 1
echo "Checking if gate port is released..."
sudo lsof -t -i:8084
echo "---"
echo 
echo "Stopping orca (for orchestrating the pipelines)..."
~/dev/spinnaker/scripts/orca-stop.sh
echo 
sleep 1
echo "Checking if orca port is released..."
sudo lsof -t -i:8083
echo "Core Spinnaker Microservices have been stopped!"
