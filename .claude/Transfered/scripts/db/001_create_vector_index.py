#!/usr/bin/env python3
"""
Migration 001: Create Azure AI Search Vector Index

This script creates the Azure AI Search index for meta-agent memory with vector search capabilities.

Prerequisites:
- Azure AI Search service deployed
- Azure CLI authenticated
- Environment variables set (AZURE_SEARCH_ENDPOINT, AZURE_SEARCH_ADMIN_KEY)

Usage:
    python 001_create_vector_index.py
"""

import os
import sys
import json
import logging
from typing import Dict, Any
from azure.core.credentials import AzureKeyCredential
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex,
    SearchField,
    SearchFieldDataType,
    SimpleField,
    SearchableField,
    VectorSearch,
    HnswAlgorithmConfiguration,
    ExhaustiveKnnAlgorithmConfiguration,
    VectorSearchProfile,
    SemanticConfiguration,
    SemanticPrioritizedFields,
    SemanticField,
    SemanticSearch,
    ScoringProfile,
    TextWeights,
    FreshnessScoringFunction,
    FreshnessScoringParameters,
    MagnitudeScoringFunction,
    MagnitudeScoringParameters,
    ScoringFunctionInterpolation,
    CorsOptions,
    SearchSuggester,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_index_definition() -> Dict[str, Any]:
    """Load index definition from JSON file."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    index_file = os.path.join(
        script_dir, '..', '..', 'infra', 'search', 'meta-agent-memory-index.json'
    )

    with open(index_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        return data['outputs']['indexDefinition']['value']


def create_search_index() -> SearchIndex:
    """Create SearchIndex object from definition."""
    index_def = load_index_definition()

    # Create fields
    fields = [
        SimpleField(
            name="id",
            type=SearchFieldDataType.String,
            key=True,
            filterable=True,
            retrievable=True
        ),
        SimpleField(
            name="agent_id",
            type=SearchFieldDataType.String,
            filterable=True,
            sortable=True,
            facetable=True,
            retrievable=True
        ),
        SimpleField(
            name="session_id",
            type=SearchFieldDataType.String,
            filterable=True,
            sortable=True,
            facetable=True,
            retrievable=True
        ),
        SimpleField(
            name="workspace_id",
            type=SearchFieldDataType.String,
            filterable=True,
            facetable=True,
            retrievable=True
        ),
        SearchableField(
            name="content",
            type=SearchFieldDataType.String,
            analyzer_name="en.microsoft",
            retrievable=True
        ),
        SearchField(
            name="content_vector",
            type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
            searchable=True,
            vector_search_dimensions=1536,
            vector_search_profile_name="vector-profile-1536-hnsw",
            retrievable=False
        ),
        SimpleField(
            name="message_type",
            type=SearchFieldDataType.String,
            filterable=True,
            facetable=True,
            retrievable=True
        ),
        SimpleField(
            name="timestamp",
            type=SearchFieldDataType.DateTimeOffset,
            filterable=True,
            sortable=True,
            retrievable=True
        ),
        SimpleField(
            name="relevance_score",
            type=SearchFieldDataType.Double,
            filterable=True,
            sortable=True,
            retrievable=True
        ),
        SimpleField(
            name="token_count",
            type=SearchFieldDataType.Int32,
            filterable=True,
            sortable=True,
            retrievable=True
        ),
        SimpleField(
            name="parent_message_id",
            type=SearchFieldDataType.String,
            filterable=True,
            retrievable=True
        ),
    ]

    # Create vector search configuration
    vector_search = VectorSearch(
        algorithms=[
            HnswAlgorithmConfiguration(
                name="hnsw-1536",
                parameters={
                    "metric": "cosine",
                    "m": 4,
                    "efConstruction": 400,
                    "efSearch": 500
                }
            ),
            ExhaustiveKnnAlgorithmConfiguration(
                name="exhaustive-1536",
                parameters={
                    "metric": "cosine"
                }
            )
        ],
        profiles=[
            VectorSearchProfile(
                name="vector-profile-1536-hnsw",
                algorithm_configuration_name="hnsw-1536"
            ),
            VectorSearchProfile(
                name="vector-profile-1536-exhaustive",
                algorithm_configuration_name="exhaustive-1536"
            )
        ]
    )

    # Create semantic search configuration
    semantic_search = SemanticSearch(
        configurations=[
            SemanticConfiguration(
                name="semantic-config",
                prioritized_fields=SemanticPrioritizedFields(
                    title_field=SemanticField(field_name="agent_id"),
                    content_fields=[SemanticField(field_name="content")]
                )
            )
        ]
    )

    # Create scoring profiles
    scoring_profiles = [
        ScoringProfile(
            name="recency-boost",
            text_weights=TextWeights(weights={"content": 2.0}),
            functions=[
                FreshnessScoringFunction(
                    field_name="timestamp",
                    boost=3.0,
                    interpolation=ScoringFunctionInterpolation.LOGARITHMIC,
                    parameters=FreshnessScoringParameters(
                        boosting_duration="P7D"
                    )
                ),
                MagnitudeScoringFunction(
                    field_name="relevance_score",
                    boost=2.0,
                    interpolation=ScoringFunctionInterpolation.LINEAR,
                    parameters=MagnitudeScoringParameters(
                        boosting_range_start=0.5,
                        boosting_range_end=1.0,
                        constant_boost_beyond_range=False
                    )
                )
            ]
        )
    ]

    # Create suggesters
    suggesters = [
        SearchSuggester(
            name="sg-content",
            source_fields=["content"]
        )
    ]

    # Create CORS options
    cors_options = CorsOptions(allowed_origins=["*"], max_age_in_seconds=300)

    # Create index
    index = SearchIndex(
        name=index_def['name'],
        fields=fields,
        vector_search=vector_search,
        semantic_search=semantic_search,
        scoring_profiles=scoring_profiles,
        default_scoring_profile="recency-boost",
        suggesters=suggesters,
        cors_options=cors_options
    )

    return index


def main():
    """Main migration function."""
    # Get Azure Search credentials from environment
    search_endpoint = os.environ.get('AZURE_SEARCH_ENDPOINT')
    search_key = os.environ.get('AZURE_SEARCH_ADMIN_KEY')

    if not search_endpoint or not search_key:
        logger.error(
            "Missing required environment variables: "
            "AZURE_SEARCH_ENDPOINT and AZURE_SEARCH_ADMIN_KEY"
        )
        sys.exit(1)

    logger.info(f"Connecting to Azure AI Search: {search_endpoint}")

    # Create search client
    credential = AzureKeyCredential(search_key)
    index_client = SearchIndexClient(
        endpoint=search_endpoint,
        credential=credential
    )

    # Create index
    logger.info("Creating search index: meta-agent-memory")
    index = create_search_index()

    try:
        result = index_client.create_or_update_index(index)
        logger.info(f"Index created successfully: {result.name}")
        logger.info(f"  - Fields: {len(result.fields)}")
        logger.info(f"  - Vector search enabled: {result.vector_search is not None}")
        logger.info(f"  - Semantic search enabled: {result.semantic_search is not None}")
        logger.info(f"  - Scoring profiles: {len(result.scoring_profiles)}")

        # Verify index exists
        existing_index = index_client.get_index(index.name)
        logger.info(f"Index verification successful: {existing_index.name}")

    except Exception as e:
        logger.error(f"Failed to create index: {str(e)}", exc_info=True)
        sys.exit(1)

    logger.info("Migration 001 completed successfully")


if __name__ == "__main__":
    main()
