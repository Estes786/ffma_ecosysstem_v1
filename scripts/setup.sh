#!/bin/bash

# FMAA Ecosystem Setup Script
echo "ðŸš€ Setting up FMAA Ecosystem..."

# Check dependencies
echo "ðŸ“‹ Checking dependencies..."

# Node.js
if ! command -v node &> /dev/null; then
    echo "âŒ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Flutter
if ! command -v flutter &> /dev/null; then
    echo "âŒ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Python
if ! command -v python3 &> /dev/null; then
    echo "âŒ Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

echo "âœ… All dependencies found"

# Install Node.js dependencies
echo "ðŸ“¦ Installing Node.js dependencies..."
npm install

# Setup Flutter dependencies
echo "ðŸ“± Setting up Flutter app..."
cd mobile-app
flutter pub get
cd ..

# Setup Python agents
echo "ðŸ Setting up Python agents..."
for agent_dir in agents/*/; do
    if [ -f "$agent_dir/requirements.txt" ]; then
        echo "Installing dependencies for $agent_dir"
        pip3 install -r "$agent_dir/requirements.txt"
    fi
done

# Copy environment template
echo "âš™ï¸ Setting up environment..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "ðŸ“ Please edit .env file with your configuration"
else
    echo "âœ… .env file already exists"
fi

# Setup database (if running locally)
if [ "$1" = "--local-db" ]; then
    echo "ðŸ—„ï¸ Setting up local database..."
    psql -d fmaa_dev -f database/schema.sql
    psql -d fmaa_dev -f database/seed_data.sql
fi

echo "ðŸŽ‰ Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Run 'npm run dev' to start development server"
echo "3. Run 'cd mobile-app && flutter run' to start mobile app"
