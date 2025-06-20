#!/bin/bash
set -e
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
ENV_FILE="$GITHUB_WORKSPACE/.env"

echo "📦 Generating .env file at $ENV_FILE"

cat <<EOF > "$ENV_FILE"
NODE_ENV=${NODE_ENV}
EOF

echo "✅ .env file created successfully!"
