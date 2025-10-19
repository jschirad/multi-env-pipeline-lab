#!/bin/bash
set -e

NAMESPACE=$1
SERVICE_NAME=$2
MAX_RETRIES=30
RETRY_INTERVAL=5

if [ -z "$NAMESPACE" ] || [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 <namespace> <service-name>"
    exit 1
fi

echo "🔍 Checking health of $SERVICE_NAME in namespace $NAMESPACE..."

for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $i/$MAX_RETRIES..."
    
    # Check if pods are running
    RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l app=webapp -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
    TOTAL_PODS=$(kubectl get pods -n $NAMESPACE -l app=webapp --no-headers | wc -l)
    
    echo "  Running pods: $RUNNING_PODS/$TOTAL_PODS"
    
    if [ $RUNNING_PODS -gt 0 ]; then
        # Check if service is accessible
        if kubectl run test-pod --rm -i --restart=Never --image=curlimages/curl:latest -n $NAMESPACE -- \
            curl -f -s http://$SERVICE_NAME.$NAMESPACE.svc.cluster.local > /dev/null 2>&1; then
            echo "✅ Health check passed! Service is healthy."
            exit 0
        fi
    fi
    
    sleep $RETRY_INTERVAL
done

echo "❌ Health check failed after $MAX_RETRIES attempts"
exit 1
