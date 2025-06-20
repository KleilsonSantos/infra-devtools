#!/bin/bash

# Path to the project (default: current directory)
PROJECT_PATH="${1:-.}"

# Path where the reports will be saved
REPORT_PATH="$(pwd)/reports"

# Create the report directory if it doesn't exist
mkdir -p "$REPORT_PATH"

# Run the Dependency-Check container
docker run --rm \
  --volume "$PROJECT_PATH":/src \
  --volume "$REPORT_PATH":/report \
  --env NVD_API_KEY="$NVD_API_KEY" \
  owasp/dependency-check \
  --scan /src \
  --format "ALL" \
  --out /report \
  --project "MyProject" \
  --nvdApiKey "$NVD_API_KEY"

echo "✅ Reports generated at: $REPORT_PATH"
echo "📁 HTML Report: $REPORT_PATH/index.html"
