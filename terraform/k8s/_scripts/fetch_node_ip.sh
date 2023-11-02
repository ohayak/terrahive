#!/bin/bash

POD_PREFIX=$1
NAMESPACE=$2

# Get the first pod that matches the prefix
POD_NAME=$(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" | grep "^$POD_PREFIX" | head -n 1)

if [ -z "$POD_NAME" ]; then
    echo "No pod found with prefix $POD_PREFIX in namespace $NAMESPACE"
    exit 1
fi

NODE_NAME=$(kubectl get pod $POD_NAME -n $NAMESPACE -o=jsonpath='{.spec.nodeName}')
NODE_IP=$(kubectl get node $NODE_NAME -o=jsonpath='{.status.addresses[?(@.type=="ExternalIP")].address}')

echo "{\"node_ip\":\"$NODE_IP\"}"
