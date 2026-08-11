#!/usr/bin/env bash
set -euo pipefail

TITLE="${1:-}"
if [ -z "$TITLE" ]; then
  echo "Usage: $0 \"Draft title\""
  exit 1
fi

# slug: lowercase, spaces -> -, keep a-z0-9 only
SLUG="$(echo "$TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"

TODAY="$(date +%Y-%m-%d)"
FILE="_drafts/${TODAY}-${SLUG}.md"

mkdir -p _drafts

if [ -e "$FILE" ]; then
  echo "Draft already exists: $FILE"
  exit 1
fi

TITLE_ESCAPED="$(printf '%s' "$TITLE" | sed 's/"/\\"/g')"

cat > "$FILE" <<EOF
---
title: "${TITLE_ESCAPED}"
layout: post
date: ${TODAY}
---

Write your draft here.
EOF

echo "Created: $FILE"
