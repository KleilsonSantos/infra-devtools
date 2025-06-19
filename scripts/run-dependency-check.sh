#!/bin/bash

PROJECT_PATH="${1:-.}"
REPORT_PATH="$(pwd)/reports"

mkdir -p "$REPORT_PATH"

docker run --rm \
  --volume "$PROJECT_PATH":/src \
  --volume "$REPORT_PATH":/report \
  owasp/dependency-check \
  --scan /src \
  --format "ALL" \
  --out /report \
  --project "MyProject"

echo "✅ Reports generated at: $REPORT_PATH"
echo "📁 HTML Report: $REPORT_PATH/index.html"
