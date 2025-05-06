#!/bin/bash

# Script to uninstall azni-app Helm release

# Set variables
RELEASE_NAME="azni-app"
NAMESPACE="azni-mysql"

# Check if release exists
if ! helm status $RELEASE_NAME -n $NAMESPACE &> /dev/null; then
  echo "Release $RELEASE_NAME does not exist in namespace $NAMESPACE."
  exit 1
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall $RELEASE_NAME from namespace $NAMESPACE? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
  echo "Uninstallation cancelled."
  exit 0
fi

# Uninstall release
echo "Uninstalling $RELEASE_NAME from namespace $NAMESPACE..."
helm uninstall $RELEASE_NAME -n $NAMESPACE

# Check if resources still exist
echo "Checking for remaining resources in namespace $NAMESPACE..."
kubectl get all -n $NAMESPACE

echo "Uninstallation completed!"
