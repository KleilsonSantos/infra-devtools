#!/bin/bash


ENV_FILE=".env"
EXAMPLE_FILE=".env.development"

echo "🔍 Validating .env using $EXAMPLE_FILE as reference..."

# 🔁 Detect if running inside GitHub Actions
if [ "$ACT" != "true" ] && [ "$GITHUB_ACTIONS" = "true" ]; then
  echo "☁️ GitHub Actions environment detected"
  if [ -n "$ENV_FILE_B64" ]; then
    echo "📥 Decoding ENV_FILE_B64 into $ENV_FILE"
    echo "$ENV_FILE_B64" | base64 -d > "$ENV_FILE"
  else
    echo "❌ ENV_FILE_B64 variable not found in secrets!"
    exit 1
  fi
else
  echo "💻 Local environment (or act): assuming .env is already generated"
fi

# 🧪 File existence check
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ $ENV_FILE not found!"
  exit 1
fi

if [ ! -f "$EXAMPLE_FILE" ]; then
  echo "❌ $EXAMPLE_FILE not found! Skipping validation."
  exit 1
fi

# 🔎 Variable-by-variable validation
MISSING=0

while IFS= read -r LINE || [ -n "$LINE" ]; do
  [[ "$LINE" =~ ^#.*$ || -z "$LINE" ]] && continue

  VAR_NAME=$(echo "$LINE" | cut -d= -f1)
  VAR_VAL=$(grep -E "^$VAR_NAME=" "$ENV_FILE" | cut -d= -f2-)

   if ! grep -q "^$VAR_NAME=" "$ENV_FILE"; then
     echo "❌ Missing: $VAR_NAME"
     MISSING=1
   elif [ -z "$VAR_VAL" ]; then
     echo "⚠️  Empty: $VAR_NAME"
   fi
done < "$EXAMPLE_FILE"

if [ "$MISSING" -eq 1 ]; then
  echo "🚫 Validation failed. Missing required variables."
  exit 1
else
  echo "✅ All required variables are present!"
fi
