#!/bin/bash

# Script to rollback azni-app Helm release

# Set variables
RELEASE_NAME="azni-app"
NAMESPACE="azni-mysql"

# Check if release exists
if ! helm status $RELEASE_NAME -n $NAMESPACE &> /dev/null; then
  echo "Release $RELEASE_NAME does not exist in namespace $NAMESPACE."
  exit 1
fi

# Show release history
echo "Release history for $RELEASE_NAME:"
helm history $RELEASE_NAME -n $NAMESPACE

# Ask for revision to rollback to
read -p "Enter revision number to rollback to (or 'q' to quit): " REVISION

if [ "$REVISION" = "q" ]; then
  echo "Rollback cancelled."
  exit 0
fi

# Validate input is a number
if ! [[ "$REVISION" =~ ^[0-9]+$ ]]; then
  echo "Error: Revision must be a number."
  exit 1
fi

# Perform rollback
echo "Rolling back $RELEASE_NAME to revision $REVISION..."
helm rollback $RELEASE_NAME $REVISION -n $NAMESPACE

# Check status after rollback
echo "Checking status after rollback..."
helm status $RELEASE_NAME -n $NAMESPACE
kubectl get pods -n $NAMESPACE

echo "Rollback completed!"
