#!/bin/bash
# AI Orchestrator - Dynamic Scaling Script

NAMESPACE="${NAMESPACE:-ai-orchestrator}"
DEPLOYMENT="${DEPLOYMENT:-ai-orchestrator}"
ACTION="${1:-status}"
REPLICAS="${2:-3}"

case $ACTION in
    up)
        echo "Scaling up to $REPLICAS replicas..."
        kubectl scale deployment/$DEPLOYMENT -n $NAMESPACE --replicas=$REPLICAS
        ;;
    down)
        echo "Scaling down to $REPLICAS replicas..."
        kubectl scale deployment/$DEPLOYMENT -n $NAMESPACE --replicas=$REPLICAS
        ;;
    auto)
        echo "Enabling autoscaling..."
        kubectl autoscale deployment/$DEPLOYMENT -n $NAMESPACE \
            --min=3 --max=10 --cpu-percent=70
        ;;
    status)
        kubectl get deployment/$DEPLOYMENT -n $NAMESPACE
        kubectl get hpa -n $NAMESPACE
        ;;
    *)
        echo "Usage: $0 {up|down|auto|status} [replicas]"
        exit 1
        ;;
esac
