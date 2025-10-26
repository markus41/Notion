#!/bin/bash

echo "Starting Bicep deployment..."
az deployment group create \
  --name webhook-deployment \
  --resource-group rg-brookside-innovation \
  --template-file "c:/Users/MarkusAhling/Notion/infrastructure/notion-webhook-function.bicep" \
  --parameters "@c:/Users/MarkusAhling/Notion/infrastructure/notion-webhook-function.parameters.json" \
  --output json > "c:/Users/MarkusAhling/Notion/infrastructure/deployment-result.json" 2>&1

EXIT_CODE=$?
echo "Deployment exit code: $EXIT_CODE"

if [ $EXIT_CODE -eq 0 ]; then
  echo "SUCCESS: Deployment completed"
  cat "c:/Users/MarkusAhling/Notion/infrastructure/deployment-result.json" | jq -r '.properties.provisioningState'
else
  echo "ERROR: Deployment failed"
  cat "c:/Users/MarkusAhling/Notion/infrastructure/deployment-result.json"
fi

exit $EXIT_CODE
