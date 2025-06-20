#!/bin/bash

echo "📦 Installing Git hooks..."

npm install husky --save-dev
echo "🐶 Husky installed successfully!"

echo "🔗 Setting up Git hooks..."
npx husky install

echo "✅ Git hook installed successfully!"