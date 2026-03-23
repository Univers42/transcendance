#!/usr/bin/env bash
# sync-docs.sh — Copy project markdown files into Docusaurus docs/ with frontmatter
# Run this before `npm run build` to populate the docs directory.
# Source of truth stays in the original locations; this script copies them.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCS_DIR="$(cd "$(dirname "$0")" && pwd)/docs"

# Helper: copy a file, prepending frontmatter if it doesn't already have it
copy_doc() {
  local src="$1"
  local dest="$2"
  local title="${3:-}"
  local position="${4:-}"

  mkdir -p "$(dirname "$dest")"

  # If file already has frontmatter (starts with ---), copy as-is
  if head -1 "$src" | grep -q '^---'; then
    cp "$src" "$dest"
    return
  fi

  # Otherwise, generate frontmatter + copy content
  {
    echo "---"
    [ -n "$title" ] && echo "title: \"$title\""
    [ -n "$position" ] && echo "sidebar_position: $position"
    echo "---"
    echo ""
    cat "$src"
  } > "$dest"
}

echo "Syncing docs from project → Docusaurus..."

# ── Root project docs ──────────────────────────────────────
copy_doc "$REPO_ROOT/README.md"           "$DOCS_DIR/intro.md"             "Introduction"          1
copy_doc "$REPO_ROOT/CONTRIBUTING.md"     "$DOCS_DIR/contributing.md"      "Contributing"          ""
copy_doc "$REPO_ROOT/CODE_OF_CONDUCT.md"  "$DOCS_DIR/code-of-conduct.md"   "Code of Conduct"       ""
copy_doc "$REPO_ROOT/SECURITY.md"         "$DOCS_DIR/security.md"          "Security"              ""
copy_doc "$REPO_ROOT/TROUBLESHOOTING.md"  "$DOCS_DIR/troubleshooting.md"   "Troubleshooting"       ""
copy_doc "$REPO_ROOT/CONTRIBUTORS.md"     "$DOCS_DIR/contributors.md"      "Contributors"          ""

# ── Technical docs (static_docs/) ──────────────────────────
copy_doc "$REPO_ROOT/static_docs/ARCHITECTURE.md"  "$DOCS_DIR/architecture.md"  "Architecture"    2
copy_doc "$REPO_ROOT/static_docs/API.md"            "$DOCS_DIR/api.md"           "API Reference"   3
copy_doc "$REPO_ROOT/static_docs/SETUP.md"          "$DOCS_DIR/setup.md"         "Setup Guide"     1
copy_doc "$REPO_ROOT/static_docs/FAQ.md"            "$DOCS_DIR/faq.md"           "FAQ"             1
copy_doc "$REPO_ROOT/static_docs/CHANGELOG.md"      "$DOCS_DIR/changelog.md"     "Changelog"       3
copy_doc "$REPO_ROOT/static_docs/subject.md"        "$DOCS_DIR/subject.md"       "Project Brief"   4

# ── Strategy ───────────────────────────────────────────────
copy_doc "$REPO_ROOT/static_docs/strategy_mini-baas.md"                "$DOCS_DIR/strategy/mini-baas.md"        "Mini-BaaS Strategy"        1
copy_doc "$REPO_ROOT/static_docs/strategy_mini-baas-infrastructure.md" "$DOCS_DIR/strategy/infrastructure.md"   "Infrastructure Strategy"   2
copy_doc "$REPO_ROOT/static_docs/prompt.md"                            "$DOCS_DIR/strategy/refactoring-plan.md" "Refactoring Plan"          3

# ── Design ─────────────────────────────────────────────────
copy_doc "$REPO_ROOT/static_docs/design/DESIGN_SYSTEM.md"    "$DOCS_DIR/design/design-system.md"    "Design System"      1
copy_doc "$REPO_ROOT/static_docs/frontend/frontend-design.md" "$DOCS_DIR/design/frontend-design.md"  "Frontend Design"    2

# ── Database ───────────────────────────────────────────────
copy_doc "$REPO_ROOT/Model/sql/sql_diagram.md"       "$DOCS_DIR/database/sql-diagram.md"       "SQL Schema"          1
copy_doc "$REPO_ROOT/Model/nosql/nosql_diagram.md"   "$DOCS_DIR/database/nosql-diagram.md"     "NoSQL Schema"        2
copy_doc "$REPO_ROOT/Model/business_mindmap.md"      "$DOCS_DIR/database/business-mindmap.md"  "Business Mindmap"    3
copy_doc "$REPO_ROOT/static_docs/norm/SQL_NORM.md"   "$DOCS_DIR/database/sql-norm.md"          "SQL Conventions"     4

# ── Fixes ──────────────────────────────────────────────────
copy_doc "$REPO_ROOT/static_docs/fixes/prisma_datasource_issue.md" "$DOCS_DIR/fixes/prisma-datasource.md" "Prisma Datasource Fix"  1
copy_doc "$REPO_ROOT/static_docs/fixes/fixing_broken_submole.md"   "$DOCS_DIR/fixes/broken-submodule.md"  "Broken Submodule Fix"   2

# ── Fix cross-doc links for Docusaurus routing ────────────
# Original files use raw .md references (for GitHub); Docusaurus needs doc paths.
fix_links() {
  local file="$1"
  local depth="${2:-0}"  # 0 = root docs/, 1 = one level deep (design/, etc.)
  [ -f "$file" ] || return

  local prefix=""
  if [ "$depth" -eq 1 ]; then
    prefix="../"
  fi

  sed -i \
    -e "s|\](../CONTRIBUTING\.md)|](${prefix}contributing)|g" \
    -e "s|\](CONTRIBUTING\.md)|](${prefix}contributing)|g" \
    -e "s|\](SECURITY\.md)|](${prefix}security)|g" \
    -e "s|\](TEAM\.md)|](${prefix}contributors)|g" \
    -e "s|\](README\.md)|](${prefix}intro)|g" \
    -e "s|\](../README\.md)|](${prefix}intro)|g" \
    "$file"
}

# Apply to files that have cross-references (depth: 0=root, 1=subfolder)
fix_links "$DOCS_DIR/intro.md" 0
fix_links "$DOCS_DIR/architecture.md" 0
fix_links "$DOCS_DIR/contributors.md" 0
fix_links "$DOCS_DIR/design/frontend-design.md" 1

echo "✅ Synced $(find "$DOCS_DIR" -name '*.md' | wc -l) docs"
