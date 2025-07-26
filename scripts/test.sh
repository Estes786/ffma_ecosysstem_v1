#!/bin/bash

# FMAA Ecosystem Test Script
echo "ðŸ§ª Running FMAA Ecosystem tests..."

# API tests
echo "ðŸ”§ Running API tests..."
npm run test:api

# Integration tests
echo "ðŸ”— Running integration tests..."
npm run test:integration

# Flutter tests
echo "ðŸ“± Running Flutter tests..."
cd mobile-app
flutter test
cd ..

# Python agent tests
echo "ðŸ Running Python agent tests..."
for agent_dir in agents/*/; do
    if [ -f "$agent_dir/test.py" ]; then
        echo "Testing $agent_dir"
        cd "$agent_dir"
        python3 -m pytest test.py
        cd - > /dev/null
    fi
done

echo "âœ… All tests completed!"
