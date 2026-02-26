#!/usr/bin/env bash
# ============================================================================
# mongo_seed.sh — Seed MongoDB with demo data
# ============================================================================
# Runs the seed_mongo.js script via mongosh to populate all 13 collections
# with demo data aligned to the PostgreSQL seeds.
#
# Usage: ./manager/mongo_seed.sh [MONGODB_URL] [DATABASE_NAME]
# ============================================================================
set -euo pipefail

MONGO_URL="${1:-${MONGODB_URL:-mongodb://localhost:27017}}"
MONGO_DB="${2:-${MONGODB_DB:-transcendence}}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEED_DIR="$(cd "$SCRIPT_DIR/../nosql/seeds" 2>/dev/null && pwd || cd "$SCRIPT_DIR/../../nosql/seeds" && pwd)"
SEED_FILE="$SEED_DIR/seed_mongo.js"

echo "════════════════════════════════════════════════════════════════"
echo "  MONGODB SEED — Demo Data"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $MONGO_URL/$MONGO_DB"
echo "  Seed:   $SEED_FILE"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ ! -f "$SEED_FILE" ]; then
    echo "✗ Seed file not found: $SEED_FILE"
    exit 1
fi

mongosh "$MONGO_URL/$MONGO_DB" --quiet --file "$SEED_FILE" 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "✗ MongoDB seeding failed (exit code $EXIT_CODE)"
    exit 1
fi
