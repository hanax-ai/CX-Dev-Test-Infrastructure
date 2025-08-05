#!/bin/bash

set -euo pipefail

QDRANT_HOST="http://192.168.10.30:6333"
COLLECTION="remote_test_collection"

echo "🌐 Connecting to Qdrant at $QDRANT_HOST"

echo "🔧 Creating collection: $COLLECTION"
curl -s -X PUT "${QDRANT_HOST}/collections/${COLLECTION}" \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 4,
      "distance": "Cosine"
    }
  }' | jq

echo "➕ Inserting test vector"
curl -s -X PUT "${QDRANT_HOST}/collections/${COLLECTION}/points" \
  -H 'Content-Type: application/json' \
  -d '{
    "points": [
      {
        "id": 1,
        "vector": [0.1, 0.2, 0.3, 0.4],
        "payload": { "source": "dev-ops", "label": "remote-test" }
      }
    ]
  }' | jq

echo "🔍 Performing search"
curl -s -X POST "${QDRANT_HOST}/collections/${COLLECTION}/points/search" \
  -H 'Content-Type: application/json' \
  -d '{
    "vector": [0.1, 0.2, 0.3, 0.4],
    "top": 1,
    "with_payload": true,
    "with_vector": true
  }' | jq
