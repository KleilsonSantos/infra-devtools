#!/bin/bash

# Absolute path to the project root
PROJECT_ROOT=$(git rev-parse --show-toplevel)
PACKAGE_FILE="$PROJECT_ROOT/package.json"

# 🔢 Current version in package.json
CURRENT_VERSION=$(jq -r '.version' "$PACKAGE_FILE")

# 🔢 Version in the last commit (HEAD)
COMMITTED_VERSION=$(git show HEAD:package.json 2>/dev/null | jq -r '.version')

echo "📦 Current version in package.json: $CURRENT_VERSION"
echo "📦 Version in the last commit: $COMMITTED_VERSION"

if [ "$CURRENT_VERSION" = "$COMMITTED_VERSION" ]; then
  echo "❌ The version in package.json has not changed since the last commit!"
  echo "💡 Please update the version before committing."
  exit 1
else
  echo "✅ Version change detected. Ready to commit!"
fi
