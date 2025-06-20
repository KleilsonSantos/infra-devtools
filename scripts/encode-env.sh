#!/bin/bash

# Path to the .env file
ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found."
  exit 1
fi

# Encode in base64
B64_CONTENT=$(base64 "$ENV_FILE" | tr -d '\n')

echo "✅ Base64-encoded content below:"
echo
echo "$B64_CONTENT"
echo
echo "🚀 Now go to your repository → Settings → Secrets → New Repository Secret"
echo "Name it ENV_FILE_B64 and paste the content above as the value."
