# Deployment Guide ðŸš€

## Overview
This guide covers deploying the FMAA ecosystem to production using Vercel, Supabase, and other cloud services.

## Prerequisites

### Required Accounts
- [Vercel](https://vercel.com) - Serverless deployment
- [Supabase](https://supabase.com) - Database and auth
- [Hugging Face](https://huggingface.co) - AI models
- [GitHub](https://github.com) - Source code

### Required Tools
- Node.js 18+
- Vercel CLI
- Flutter SDK (for mobile)
- Git

## Database Setup

### 1. Create Supabase Project
```bash
# Create new project at https://supabase.com/dashboard
# Note your project URL and API keys
```

### 2. Setup Database Schema
```bash
# Run schema migration
psql -h your-db-host -U postgres -d postgres -f database/schema.sql

# Seed initial data
psql -h your-db-host -U postgres -d postgres -f database/seed_data.sql
```

### 3. Configure Row Level Security
```sql
-- Enable RLS for all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
-- ... repeat for all tables
```

## Backend Deployment

### 1. Environment Variables
Create these in your Vercel dashboard:

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Hugging Face
HUGGINGFACE_API_KEY=your-hf-api-key

# Security
JWT_SECRET=your-long-random-secret

# API Configuration
NODE_ENV=production
```

### 2. Deploy to Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

### 3. Configure Custom Domain (Optional)
```bash
# Add custom domain in Vercel dashboard
vercel domains add your-domain.com
```

## Mobile App Deployment

### Android Deployment

1. **Prepare for Release**
```bash
cd mobile-app
flutter build apk --release
```

2. **Google Play Store**
```bash
# Create app bundle
flutter build appbundle --release

# Upload to Play Console
# Follow Google Play Console instructions
```

### iOS Deployment

1. **Build for iOS**
```bash
flutter build ios --release
```

2. **App Store Connect**
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Archive and upload to App Store Connect
```

## Web Dashboard Deployment

### 1. Build Web Dashboard
```bash
cd web-dashboard
npm install
npm run build
```

### 2. Deploy to Vercel
```bash
# Deploy from web-dashboard directory
vercel --prod
```

## Python Agents Deployment

### 1. Containerize Agents
```dockerfile
# Dockerfile for each agent
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
CMD ["python", "model.py"]
```

### 2. Deploy to Cloud Run (Optional)
```bash
# Build and deploy each agent
gcloud builds submit --tag gcr.io/your-project/sentiment-agent
gcloud run deploy sentiment-agent --image gcr.io/your-project/sentiment-agent
```

## Monitoring Setup

### 1. Error Tracking
```javascript
// Add to your Vercel functions
import { captureException } from '@sentry/node';

// Initialize Sentry
Sentry.init({
  dsn: process.env.SENTRY_DSN,
});
```

### 2. Performance Monitoring
```javascript
// Add performance monitoring
import { performance } from 'perf_hooks';

const startTime = performance.now();
// ... your code ...
const endTime = performance.now();
console.log(`Execution time: ${endTime - startTime}ms`);
```

## Security Configuration

### 1. CORS Settings
```javascript
// In your API functions
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://your-domain.com',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};
```

### 2. Rate Limiting
```javascript
// Implement rate limiting
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
});
```

## SSL/TLS Configuration

Vercel provides automatic SSL certificates. For custom domains:

```bash
# SSL is automatic with Vercel
# No additional configuration needed
```

## Backup Strategy

### 1. Database Backups
```bash
# Automated backups in Supabase
# Configure in Supabase dashboard
```

### 2. Code Backups
```bash
# Ensure all code is in GitHub
git push origin main
```

## Performance Optimization

### 1. CDN Configuration
```javascript
// Vercel automatically provides CDN
// Configure caching headers
export default function handler(req, res) {
  res.setHeader('Cache-Control', 's-maxage=60, stale-while-revalidate');
  // ... your code
}
```

### 2. Database Optimization
```sql
-- Add indexes for better performance
CREATE INDEX idx_agents_tenant_id ON agents(tenant_id);
CREATE INDEX idx_tasks_agent_id ON agent_tasks(agent_id);
CREATE INDEX idx_tasks_status ON agent_tasks(status);
```

## Health Checks

### 1. API Health Endpoints
```javascript
// Add to each API function
export default function handler(req, res) {
  if (req.method === 'GET' && req.url === '/health') {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
    return;
  }
  // ... rest of your code
}
```

### 2. Database Health Check
```javascript
// Check database connectivity
const healthCheck = async () => {
  try {
    const { data, error } = await supabase.from('agents').select('count');
    return !error;
  } catch (err) {
    return false;
  }
};
```

## Troubleshooting

### Common Issues

1. **Database Connection Timeout**
```bash
# Check your Supabase project status
# Verify environment variables
```

2. **API Rate Limiting**
```bash
# Check your Hugging Face API limits
# Implement caching for API responses
```

3. **Memory Limits**
```bash
# Optimize your serverless functions
# Use streaming for large responses
```

### Logs and Debugging

```bash
# View Vercel logs
vercel logs

# Check Supabase logs in dashboard
# Monitor Hugging Face API usage
```

## Scaling Considerations

### 1. Serverless Function Limits
- Max execution time: 10 seconds (hobby), 60 seconds (pro)
- Memory limit: 1GB
- Concurrent executions: 1000

### 2. Database Scaling
- Connection pooling in Supabase
- Read replicas for heavy read workloads
- Proper indexing strategy

### 3. AI Model Scaling
- Consider caching model responses
- Implement model switching for different loads
- Use edge caching for common requests

## Cost Optimization

### 1. Vercel Costs
- Functions: $0.20 per 1M requests
- Bandwidth: $0.12 per GB
- Storage: $0.10 per GB/month

### 2. Supabase Costs
- Database: $25/month for 8GB
- Additional storage: $0.125 per GB/month
- Bandwidth: $0.09 per GB

### 3. Hugging Face Costs
- Free tier: 1000 requests/month
- Pro tier: $9/month for 100k requests
- Enterprise: Custom pricing

## Maintenance

### 1. Regular Updates
```bash
# Update dependencies monthly
npm update
flutter pub upgrade
```

### 2. Security Updates
```bash
# Monitor security advisories
npm audit
```

### 3. Performance Monitoring
```bash
# Set up alerts for performance degradation
# Monitor error rates and response times
```

---

For additional support, refer to the documentation or contact the development team.
