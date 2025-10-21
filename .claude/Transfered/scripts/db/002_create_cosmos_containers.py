#!/usr/bin/env python3
"""
Migration 002: Create Cosmos DB Containers

This script creates all required Cosmos DB containers for the meta-agent platform.
It uses the Azure Cosmos DB SDK for Python to programmatically create containers
with custom indexing policies and TTL settings.

Prerequisites:
- Azure Cosmos DB account deployed
- Azure CLI authenticated or connection string set
- Environment variables set (COSMOS_DB_ENDPOINT, COSMOS_DB_KEY)

Usage:
    python 002_create_cosmos_containers.py
"""

import os
import sys
import logging
from typing import Dict, Any, List
from azure.cosmos import CosmosClient, PartitionKey, exceptions

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_container_definitions() -> List[Dict[str, Any]]:
    """
    Return container definitions matching the Bicep template.

    Returns:
        List of container definitions with name, partition key, TTL, and indexing policy.
    """
    return [
        # Existing containers (backward compatibility)
        {
            "name": "thread-message-store",
            "partition_key": "/threadId",
            "default_ttl": -1,  # No automatic expiration
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [{"path": "/*"}],
                "excludedPaths": [{"path": "/_etag/?"}]
            }
        },
        {
            "name": "system-thread-message-store",
            "partition_key": "/threadId",
            "default_ttl": -1,
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [{"path": "/*"}],
                "excludedPaths": [{"path": "/_etag/?"}]
            }
        },
        {
            "name": "agent-entity-store",
            "partition_key": "/agentId",
            "default_ttl": -1,
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [{"path": "/*"}],
                "excludedPaths": [{"path": "/_etag/?"}]
            }
        },
        # New meta-agent platform containers
        {
            "name": "workflow-states",
            "partition_key": "/workflow_id",
            "default_ttl": 2592000,  # 30 days
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [
                    {"path": "/workflow_id/?"},
                    {"path": "/workspace_id/?"},
                    {"path": "/status/?"},
                    {"path": "/type/?"},
                    {"path": "/created_at/?"},
                    {"path": "/updated_at/?"},
                    {"path": "/current_step/?"}
                ],
                "excludedPaths": [
                    {"path": "/_etag/?"},
                    {"path": "/agents/*/result/*"},
                    {"path": "/checkpoints/*/state/*"}
                ],
                "compositeIndexes": [
                    [
                        {"path": "/workspace_id", "order": "ascending"},
                        {"path": "/status", "order": "ascending"},
                        {"path": "/created_at", "order": "descending"}
                    ],
                    [
                        {"path": "/workspace_id", "order": "ascending"},
                        {"path": "/type", "order": "ascending"},
                        {"path": "/updated_at", "order": "descending"}
                    ]
                ]
            }
        },
        {
            "name": "agent-memories",
            "partition_key": "/agent_id",
            "default_ttl": 7776000,  # 90 days
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [
                    {"path": "/agent_id/?"},
                    {"path": "/session_id/?"},
                    {"path": "/workspace_id/?"},
                    {"path": "/message_type/?"},
                    {"path": "/timestamp/?"},
                    {"path": "/relevance_score/?"}
                ],
                "excludedPaths": [
                    {"path": "/_etag/?"},
                    {"path": "/content/?"},
                    {"path": "/metadata/tool_result/?"}
                ],
                "compositeIndexes": [
                    [
                        {"path": "/agent_id", "order": "ascending"},
                        {"path": "/session_id", "order": "ascending"},
                        {"path": "/timestamp", "order": "ascending"}
                    ],
                    [
                        {"path": "/workspace_id", "order": "ascending"},
                        {"path": "/agent_id", "order": "ascending"},
                        {"path": "/relevance_score", "order": "descending"}
                    ]
                ]
            }
        },
        {
            "name": "agent-metrics",
            "partition_key": "/metric_date",
            "default_ttl": 15552000,  # 180 days
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [
                    {"path": "/metric_date/?"},
                    {"path": "/agent_id/?"},
                    {"path": "/workspace_id/?"},
                    {"path": "/metric_type/?"},
                    {"path": "/timestamp/?"}
                ],
                "excludedPaths": [
                    {"path": "/_etag/?"}
                ],
                "compositeIndexes": [
                    [
                        {"path": "/metric_date", "order": "descending"},
                        {"path": "/agent_id", "order": "ascending"},
                        {"path": "/metric_type", "order": "ascending"}
                    ]
                ]
            }
        },
        {
            "name": "tool-invocations",
            "partition_key": "/tool_date",
            "default_ttl": 7776000,  # 90 days
            "indexing_policy": {
                "indexingMode": "consistent",
                "automatic": True,
                "includedPaths": [
                    {"path": "/tool_date/?"},
                    {"path": "/tool_name/?"},
                    {"path": "/agent_id/?"},
                    {"path": "/workspace_id/?"},
                    {"path": "/status/?"},
                    {"path": "/timestamp/?"}
                ],
                "excludedPaths": [
                    {"path": "/_etag/?"},
                    {"path": "/input_args/*"},
                    {"path": "/output_result/*"},
                    {"path": "/error_details/*"}
                ],
                "compositeIndexes": [
                    [
                        {"path": "/tool_date", "order": "descending"},
                        {"path": "/tool_name", "order": "ascending"},
                        {"path": "/status", "order": "ascending"}
                    ]
                ]
            }
        }
    ]


def create_container(database, container_def: Dict[str, Any]) -> None:
    """
    Create a single container with specified configuration.

    Args:
        database: Cosmos DB database object
        container_def: Container definition dictionary
    """
    container_name = container_def["name"]

    logger.info(f"Creating container: {container_name}")

    try:
        # Check if container already exists
        try:
            existing = database.get_container_client(container_name)
            existing.read()
            logger.info(f"  Container already exists: {container_name}")
            logger.info(f"  Skipping creation (use manual update to modify existing container)")
            return
        except exceptions.CosmosResourceNotFoundError:
            # Container doesn't exist, proceed with creation
            pass

        # Create container
        container = database.create_container(
            id=container_name,
            partition_key=PartitionKey(path=container_def["partition_key"]),
            indexing_policy=container_def["indexing_policy"],
            default_ttl=container_def["default_ttl"]
        )

        logger.info(f"  Successfully created: {container_name}")
        logger.info(f"    - Partition key: {container_def['partition_key']}")
        logger.info(f"    - Default TTL: {container_def['default_ttl']} seconds")
        logger.info(f"    - Indexing mode: {container_def['indexing_policy']['indexingMode']}")

        if "compositeIndexes" in container_def["indexing_policy"]:
            composite_count = len(container_def["indexing_policy"]["compositeIndexes"])
            logger.info(f"    - Composite indexes: {composite_count}")

    except exceptions.CosmosHttpResponseError as e:
        logger.error(f"  Failed to create container {container_name}: {str(e)}")
        raise


def main():
    """Main migration function."""
    # Get Cosmos DB credentials from environment
    cosmos_endpoint = os.environ.get('COSMOS_DB_ENDPOINT')
    cosmos_key = os.environ.get('COSMOS_DB_KEY')
    database_name = os.environ.get('COSMOS_DB_DATABASE', 'project-ascension-db')

    if not cosmos_endpoint or not cosmos_key:
        logger.error(
            "Missing required environment variables: "
            "COSMOS_DB_ENDPOINT and COSMOS_DB_KEY"
        )
        sys.exit(1)

    logger.info(f"Connecting to Cosmos DB: {cosmos_endpoint}")
    logger.info(f"Database: {database_name}")

    # Create Cosmos client
    client = CosmosClient(cosmos_endpoint, cosmos_key)

    # Get or create database
    try:
        database = client.get_database_client(database_name)
        database.read()
        logger.info(f"Database exists: {database_name}")
    except exceptions.CosmosResourceNotFoundError:
        logger.info(f"Database not found, creating: {database_name}")
        database = client.create_database(database_name)
        logger.info(f"Database created: {database_name}")

    # Get container definitions
    containers = get_container_definitions()
    logger.info(f"\nCreating {len(containers)} containers...\n")

    # Create each container
    success_count = 0
    error_count = 0

    for container_def in containers:
        try:
            create_container(database, container_def)
            success_count += 1
        except Exception as e:
            logger.error(f"Error creating container: {str(e)}")
            error_count += 1

    # Summary
    logger.info(f"\n{'='*60}")
    logger.info(f"Migration 002 completed")
    logger.info(f"  - Total containers: {len(containers)}")
    logger.info(f"  - Successful: {success_count}")
    logger.info(f"  - Errors: {error_count}")
    logger.info(f"{'='*60}\n")

    if error_count > 0:
        logger.warning(f"{error_count} containers failed to create")
        sys.exit(1)

    logger.info("All containers created successfully")


if __name__ == "__main__":
    main()
