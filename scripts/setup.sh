#!/bin/bash

# -------------------------------------------
# 🛠️ Initial Project Setup Script
# -------------------------------------------
BASE_DIR="/home/operador/Development/github/infra-devtools"
echo "🚀 Starting initial project setup in $BASE_DIR..."

# Function to print formatted messages
function print_message() {
  echo -e "\n🔧 $1\n"
}

# Check if Docker is installed
print_message "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not found. Please install Docker before proceeding."
  exit 1
fi

# Check if Docker Compose is installed
print_message "Checking if Docker Compose is installed..."
if ! command -v docker-compose &> /dev/null; then
  echo "❌ Docker Compose not found. Please install Docker Compose before proceeding."
  exit 1
fi

# Create .env file if it doesn't exist
print_message "Setting up .env file..."
if [ ! -f $BASE_DIR/.env ]; then
  cp $BASE_DIR/.env.development $BASE_DIR/.env.default
  echo "✅ .env file created based on .env.example. Please edit it to adjust environment variables."
else
  echo "✅ .env file already exists. No action needed."
fi

# Create necessary directories
print_message "Creating necessary directories..."
mkdir -p reports
echo "✅ 'reports/' directory created (if it didn’t exist)."

# Install Node.js dependencies
print_message "Installing Node.js dependencies..."
if [ -f $BASE_DIR/package.json ]; then
  npm install
  echo "✅ Node.js dependencies installed."
else
  echo "⚠️ package.json file not found. Skipping Node.js dependency installation."
fi

# Check OWASP Dependency-Check setup
print_message "Checking OWASP Dependency-Check setup..."
if [ ! -f $BASE_DIR/scripts/run-dependency-check.sh ]; then
  echo "❌ 'run-dependency-check.sh' script not found. Make sure it exists in the 'scripts/' directory."
else
  chmod +x $BASE_DIR/scripts/run-dependency-check.sh
  echo "✅ 'run-dependency-check.sh' script configured."
fi

# Check SonarQube environment variables
print_message "Checking SonarQube configuration..."
if [ -z "$SONAR_HOST_URL" ] || [ -z "$SONAR_TOKEN_INFRA_DEVTOOLS" ]; then
  echo "⚠️ SonarQube environment variables not set. Please ensure 'SONAR_HOST_URL' and 'SONAR_TOKEN_INFRA_DEVTOOLS' are defined in the .env file."
else
  echo "✅ SonarQube configuration detected."
fi

# Check if Python is installed
print_message "Setting Python virtual environment..."
python3 -m venv .venv
if [ -d ".venv" ]; then
  echo "✅ Python virtual environment created at '.venv'."
else
  echo "❌ Failed to create Python virtual environment. Please check your Python installation."
  exit 1
fi

# Activate the virtual environment
source .venv/bin/activate

# Install Python dependencies
print_message "Installing Python dependencies..."
pip3 install pytest
pip3 install pytest-cov
pip3 install pytest-html
pip3 install testcontainers
pip3 install psycopg2
pip3 install dotenv
pip3 install requests
pip3 install pytest-mock
pip3 install logging
pip3 install testinfra
echo "✅ Python dependencies installed."

# Done!
print_message "Initial setup completed! 🚀"
echo "📄 Please review the .env file and adjust environment variables as needed."
echo "✅ You can now start the infrastructure using 'make up' or 'npm run start'."
