#!/bin/bash

# FMAA Ecosystem Deploy Script
echo "ðŸš€ Deploying FMAA Ecosystem..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "âŒ .env file not found. Please create it first."
    exit 1
fi

# Run tests
echo "ðŸ§ª Running tests..."
npm test
if [ $? -ne 0 ]; then
    echo "âŒ Tests failed. Deploy aborted."
    exit 1
fi

# Build web dashboard
echo "ðŸ—ï¸ Building web dashboard..."
cd web-dashboard
npm run build
cd ..

# Build Flutter app for release
echo "ðŸ“± Building Flutter app..."
cd mobile-app
flutter build apk --release
flutter build web --release
cd ..

# Deploy to Vercel
echo "â˜ï¸ Deploying to Vercel..."
vercel --prod

# Deploy agents (if needed)
echo "ðŸ¤– Deploying agents..."
# Add specific deployment logic for Python agents if needed

echo "âœ… Deployment completed successfully!"
echo "ðŸŒ Check your Vercel dashboard for the deployed URLs"
