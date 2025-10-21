#!/usr/bin/env python3
"""
Migration 003: Seed Initial Data

This script seeds initial test data into Cosmos DB and Azure AI Search for
development and testing purposes.

Prerequisites:
- Cosmos DB containers created (run 002_create_cosmos_containers.py)
- Azure AI Search index created (run 001_create_vector_index.py)
- Environment variables set

Usage:
    python 003_seed_initial_data.py
"""

import os
import sys
import logging
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any
from azure.cosmos import CosmosClient
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def generate_workflow_states() -> List[Dict[str, Any]]:
    """Generate sample workflow state documents."""
    base_time = datetime.now(timezone.utc) - timedelta(hours=2)

    return [
        {
            "id": "550e8400-e29b-41d4-a716-446655440001",
            "workflow_id": "workflow-demo-001",
            "workspace_id": "ws-demo-tenant",
            "type": "sequential",
            "name": "API Development Workflow",
            "description": "Design, implement, and test REST API endpoints",
            "status": "completed",
            "current_step": 3,
            "total_steps": 3,
            "agents": [
                {
                    "agent_id": "architect-001",
                    "agent_name": "System Architect",
                    "status": "completed",
                    "started_at": (base_time).isoformat(),
                    "completed_at": (base_time + timedelta(minutes=5)).isoformat(),
                    "duration_ms": 300000,
                    "result": {
                        "output": {
                            "api_design": {
                                "endpoints": ["/api/users", "/api/products"],
                                "auth_method": "JWT"
                            }
                        },
                        "tool_calls": [],
                        "token_usage": {
                            "prompt_tokens": 1500,
                            "completion_tokens": 800,
                            "total_tokens": 2300
                        },
                        "error": None
                    }
                },
                {
                    "agent_id": "developer-002",
                    "agent_name": "Backend Developer",
                    "status": "completed",
                    "started_at": (base_time + timedelta(minutes=5)).isoformat(),
                    "completed_at": (base_time + timedelta(minutes=25)).isoformat(),
                    "duration_ms": 1200000,
                    "result": {
                        "output": {
                            "code_files": ["users.py", "products.py"],
                            "tests_created": True
                        },
                        "tool_calls": [
                            {
                                "tool_name": "code_executor",
                                "tool_args": {"language": "python"},
                                "tool_result": "success",
                                "duration_ms": 5000,
                                "error": None
                            }
                        ],
                        "token_usage": {
                            "prompt_tokens": 3000,
                            "completion_tokens": 2000,
                            "total_tokens": 5000
                        },
                        "error": None
                    }
                },
                {
                    "agent_id": "tester-003",
                    "agent_name": "QA Engineer",
                    "status": "completed",
                    "started_at": (base_time + timedelta(minutes=25)).isoformat(),
                    "completed_at": (base_time + timedelta(minutes=35)).isoformat(),
                    "duration_ms": 600000,
                    "result": {
                        "output": {
                            "tests_passed": 15,
                            "tests_failed": 0,
                            "coverage": 95.5
                        },
                        "tool_calls": [],
                        "token_usage": {
                            "prompt_tokens": 1000,
                            "completion_tokens": 500,
                            "total_tokens": 1500
                        },
                        "error": None
                    }
                }
            ],
            "checkpoints": [
                {
                    "step": 0,
                    "timestamp": base_time.isoformat(),
                    "state": {"initialized": True, "agents_loaded": True},
                    "agent_context": {}
                },
                {
                    "step": 1,
                    "timestamp": (base_time + timedelta(minutes=5)).isoformat(),
                    "state": {"architect_completed": True},
                    "agent_context": {"architect-001": {"conversation_id": "conv-123"}}
                },
                {
                    "step": 2,
                    "timestamp": (base_time + timedelta(minutes=25)).isoformat(),
                    "state": {"developer_completed": True},
                    "agent_context": {"developer-002": {"conversation_id": "conv-124"}}
                }
            ],
            "metadata": {
                "created_by": "demo-user",
                "tags": ["api-development", "backend", "demo"],
                "priority": 5,
                "retry_count": 0,
                "max_retries": 3,
                "timeout_seconds": 3600,
                "environment": "development"
            },
            "performance_metrics": {
                "total_duration_ms": 2100000,
                "queue_time_ms": 1200,
                "execution_time_ms": 2100000,
                "avg_step_duration_ms": 700000,
                "total_cost_usd": 0.18
            },
            "error_details": None,
            "created_at": base_time.isoformat(),
            "updated_at": (base_time + timedelta(minutes=35)).isoformat(),
            "completed_at": (base_time + timedelta(minutes=35)).isoformat(),
            "ttl": 2592000
        }
    ]


def generate_agent_memories() -> List[Dict[str, Any]]:
    """Generate sample agent memory documents."""
    base_time = datetime.now(timezone.utc) - timedelta(hours=1)

    return [
        {
            "id": f"msg-{uuid.uuid4()}",
            "agent_id": "architect-001",
            "session_id": "session-demo-001",
            "workspace_id": "ws-demo-tenant",
            "content": "Design a REST API for user management with JWT authentication and role-based access control.",
            "message_type": "user",
            "timestamp": base_time.isoformat(),
            "relevance_score": 0.95,
            "token_count": 24,
            "parent_message_id": None,
            "metadata": {
                "tool_name": None,
                "tool_args": None,
                "tool_result": None,
                "reasoning_chain": [],
                "tags": ["api-design", "authentication", "rbac"],
                "model": "gpt-4",
                "temperature": 0.7,
                "user_id": "demo-user"
            },
            "created_at": base_time.isoformat(),
            "ttl": 7776000
        },
        {
            "id": f"msg-{uuid.uuid4()}",
            "agent_id": "architect-001",
            "session_id": "session-demo-001",
            "workspace_id": "ws-demo-tenant",
            "content": "I'll design a comprehensive REST API with the following endpoints: POST /api/auth/login, POST /api/auth/register, GET /api/users, POST /api/users, PUT /api/users/:id, DELETE /api/users/:id. Authentication will use JWT tokens with refresh token rotation.",
            "message_type": "assistant",
            "timestamp": (base_time + timedelta(seconds=30)).isoformat(),
            "relevance_score": 0.98,
            "token_count": 56,
            "parent_message_id": None,
            "metadata": {
                "tool_name": None,
                "tool_args": None,
                "tool_result": None,
                "reasoning_chain": [
                    "Identify authentication requirements",
                    "Design endpoint structure",
                    "Plan JWT implementation"
                ],
                "tags": ["api-design", "endpoints", "jwt"],
                "model": "gpt-4",
                "temperature": 0.7,
                "user_id": None
            },
            "created_at": (base_time + timedelta(seconds=30)).isoformat(),
            "ttl": 7776000
        }
    ]


def generate_agent_metrics() -> List[Dict[str, Any]]:
    """Generate sample agent metrics documents."""
    today = datetime.now(timezone.utc).date().isoformat()
    base_time = datetime.now(timezone.utc) - timedelta(hours=1)

    metrics = []
    for i in range(10):
        timestamp = base_time + timedelta(minutes=i * 5)
        metrics.append({
            "id": f"metric-{uuid.uuid4()}",
            "metric_date": today,
            "agent_id": "architect-001",
            "workspace_id": "ws-demo-tenant",
            "metric_type": "latency",
            "timestamp": timestamp.isoformat(),
            "value": 300000 + (i * 10000),  # Increasing latency
            "dimensions": {
                "session_id": "session-demo-001",
                "workflow_id": "workflow-demo-001",
                "environment": "development",
                "model": "gpt-4",
                "tool_name": None
            },
            "created_at": timestamp.isoformat(),
            "ttl": 15552000
        })

    return metrics


def generate_tool_invocations() -> List[Dict[str, Any]]:
    """Generate sample tool invocation documents."""
    today = datetime.now(timezone.utc).date().isoformat()
    base_time = datetime.now(timezone.utc) - timedelta(hours=1)

    return [
        {
            "id": f"tool-{uuid.uuid4()}",
            "tool_date": today,
            "tool_name": "code_executor",
            "agent_id": "developer-002",
            "workspace_id": "ws-demo-tenant",
            "session_id": "session-demo-001",
            "workflow_id": "workflow-demo-001",
            "timestamp": (base_time + timedelta(minutes=10)).isoformat(),
            "status": "success",
            "duration_ms": 5000,
            "input_args": {
                "language": "python",
                "code": "print('Hello, World!')"
            },
            "output_result": {
                "stdout": "Hello, World!\n",
                "stderr": "",
                "exit_code": 0
            },
            "error_details": None,
            "security_context": {
                "user_id": "demo-user",
                "ip_address": "127.0.0.1",
                "user_agent": "Python-Agent/1.0"
            },
            "created_at": (base_time + timedelta(minutes=10)).isoformat(),
            "ttl": 7776000
        }
    ]


def seed_cosmos_container(client: CosmosClient, database_name: str, container_name: str, documents: List[Dict[str, Any]]):
    """Seed documents into a Cosmos DB container."""
    logger.info(f"Seeding {len(documents)} documents into {container_name}...")

    database = client.get_database_client(database_name)
    container = database.get_container_client(container_name)

    success_count = 0
    for doc in documents:
        try:
            container.upsert_item(doc)
            success_count += 1
        except Exception as e:
            logger.error(f"  Error inserting document {doc['id']}: {str(e)}")

    logger.info(f"  Successfully seeded {success_count}/{len(documents)} documents")


def main():
    """Main seeding function."""
    # Get credentials from environment
    cosmos_endpoint = os.environ.get('COSMOS_DB_ENDPOINT')
    cosmos_key = os.environ.get('COSMOS_DB_KEY')
    database_name = os.environ.get('COSMOS_DB_DATABASE', 'project-ascension-db')

    if not cosmos_endpoint or not cosmos_key:
        logger.error(
            "Missing required environment variables: "
            "COSMOS_DB_ENDPOINT and COSMOS_DB_KEY"
        )
        sys.exit(1)

    logger.info("Starting data seeding process...\n")

    # Create Cosmos client
    cosmos_client = CosmosClient(cosmos_endpoint, cosmos_key)

    # Seed Cosmos DB containers
    logger.info("Seeding Cosmos DB containers...")
    seed_cosmos_container(cosmos_client, database_name, "workflow-states", generate_workflow_states())
    seed_cosmos_container(cosmos_client, database_name, "agent-memories", generate_agent_memories())
    seed_cosmos_container(cosmos_client, database_name, "agent-metrics", generate_agent_metrics())
    seed_cosmos_container(cosmos_client, database_name, "tool-invocations", generate_tool_invocations())

    logger.info("\n" + "="*60)
    logger.info("Migration 003 completed successfully")
    logger.info("="*60 + "\n")

    logger.info("Note: Azure AI Search seeding requires embeddings generation.")
    logger.info("Use the VectorStoreClient in your application to add documents with embeddings.")


if __name__ == "__main__":
    main()
