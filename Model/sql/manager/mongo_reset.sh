#!/usr/bin/env bash
# ============================================================================
# mongo_reset.sh — Drop the MongoDB database
# ============================================================================
# Drops the entire transcendence MongoDB database. Used before re-seeding
# to ensure a clean state.
#
# Usage: ./manager/mongo_reset.sh [MONGODB_URL] [DATABASE_NAME]
# ============================================================================
set -euo pipefail

MONGO_URL="${1:-${MONGODB_URL:-mongodb://localhost:27017}}"
MONGO_DB="${2:-${MONGODB_DB:-transcendence}}"

echo "════════════════════════════════════════════════════════════════"
echo "  MONGODB RESET — Drop Database"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $MONGO_URL/$MONGO_DB"
echo "════════════════════════════════════════════════════════════════"
echo ""

mongosh "$MONGO_URL/$MONGO_DB" --quiet --eval "
    db.dropDatabase();
    print('✓ Database \"$MONGO_DB\" dropped.');
" 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "✗ MongoDB reset failed (exit code $EXIT_CODE)"
    exit 1
fi
