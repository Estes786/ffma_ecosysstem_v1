# FMAA Ecosystem ðŸš€

**Federated Micro-Agents Architecture** - A comprehensive AI-powered microservices ecosystem

## ðŸŒŸ Features

- **Multi-Agent Architecture**: Federated micro-agents for different AI tasks
- **Real-time Monitoring**: Live dashboard for agents and tasks
- **Multi-tenant Support**: Secure isolation for different organizations
- **Serverless Deployment**: Optimized for Vercel and modern cloud platforms
- **Cross-platform**: Web dashboard and Flutter mobile app
- **AI-Powered**: Integrated with Hugging Face models

## ðŸ“‹ Tech Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Serverless Functions (Vercel)
- **Database**: PostgreSQL with Supabase
- **AI/ML**: Hugging Face Transformers
- **Authentication**: JWT with Supabase Auth

### Frontend
- **Web**: Next.js 13+ with React
- **Mobile**: Flutter 3.0+
- **UI**: Material Design 3
- **Charts**: Chart.js / FL Chart
- **Real-time**: Supabase Real-time

### AI Agents
- **Sentiment Analysis**: Text emotion detection
- **Recommendation**: Content similarity matching
- **Performance Monitor**: System health tracking

## ðŸš€ Quick Start

### Prerequisites
- Node.js 18+
- Flutter 3.0+
- Python 3.8+
- Supabase account
- Hugging Face API key

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd fmaa-ecosystem
```

2. **Run setup script**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

3. **Configure environment**
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. **Setup database**
```bash
# Run migrations on Supabase
psql -h <your-supabase-host> -U postgres -d postgres -f database/schema.sql
```

5. **Start development**
```bash
# Start API server
npm run dev

# Start mobile app (in another terminal)
cd mobile-app
flutter run
```

## ðŸ“ Project Structure

```
fmaa-ecosystem/
â”œâ”€â”€ ðŸ“ api/                 # Serverless API functions
â”‚   â”œâ”€â”€ ðŸš€ agent-factory.js    # Agent management
â”‚   â”œâ”€â”€ ðŸ’­ sentiment-agent.js  # Sentiment analysis
â”‚   â”œâ”€â”€ â­ recommendation-agent.js # Recommendations
â”‚   â”œâ”€â”€ ðŸ“Š performance-monitor.js # Performance monitoring
â”‚   â””â”€â”€ ðŸ“ utils/               # Shared utilities
â”œâ”€â”€ ðŸ“ database/            # Database schema & migrations
â”œâ”€â”€ ðŸ“ mobile-app/          # Flutter mobile application
â”œâ”€â”€ ðŸ“ web-dashboard/       # Next.js web dashboard
â”œâ”€â”€ ðŸ“ agents/              # Python agent implementations
â”œâ”€â”€ ðŸ“ shared/              # Shared constants & types
â”œâ”€â”€ ðŸ“ scripts/             # Deployment & setup scripts
â””â”€â”€ ðŸ“ docs/                # Documentation
```

## ðŸ¤– Agents

### Sentiment Agent
- **Purpose**: Analyze text sentiment and emotions
- **Model**: Hugging Face sentiment analysis models
- **API**: `/api/sentiment-agent`

### Recommendation Agent
- **Purpose**: Find similar content using embeddings
- **Model**: Hugging Face text embedding models
- **API**: `/api/recommendation-agent`

### Performance Monitor
- **Purpose**: Track system health and performance
- **Metrics**: Response time, error rates, resource usage
- **API**: `/api/performance-monitor`

## ðŸ”§ Configuration

### Environment Variables
```env
# Supabase
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Hugging Face
HUGGINGFACE_API_KEY=your_huggingface_api_key

# JWT
JWT_SECRET=your_jwt_secret

# API Endpoints
API_BASE_URL=http://localhost:3000
```

## ðŸš€ Deployment

### Vercel Deployment
```bash
# Deploy to production
./scripts/deploy.sh

# Or manually
npm run build
vercel --prod
```

### Mobile App Deployment
```bash
# Android
cd mobile-app
flutter build apk --release

# iOS
flutter build ios --release
```

## ðŸ§ª Testing

```bash
# Run all tests
./scripts/test.sh

# Specific test suites
npm run test:api
npm run test:integration
cd mobile-app && flutter test
```

## ðŸ“Š Monitoring

### Real-time Dashboard
- Agent status and health
- Task execution metrics
- System performance indicators
- Error tracking and alerting

### API Endpoints
- `GET /api/agent-factory` - List all agents
- `POST /api/sentiment-agent` - Analyze sentiment
- `POST /api/recommendation-agent` - Get recommendations
- `GET /api/performance-monitor/report` - System report

## ðŸ” Security

- **Multi-tenant**: Row Level Security (RLS)
- **Authentication**: JWT-based auth
- **API Keys**: Secure key management
- **CORS**: Configured for web security
- **Rate Limiting**: Built-in protection

## ðŸ“± Mobile App

### Features
- **Dashboard**: System overview and metrics
- **Agent Management**: Create, configure, and monitor agents
- **Task Monitoring**: Track task execution and results
- **Real-time Updates**: Live data synchronization

### Screenshots
[Add screenshots here]

## ðŸ¤ Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## ðŸ“„ License

This project is licensed under the MIT License - see the LICENSE file for details.

## ðŸ†˜ Support

- **Documentation**: [docs/](./docs/)
- **API Reference**: [docs/API_REFERENCE.md](./docs/API_REFERENCE.md)
- **Deployment Guide**: [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)

## ðŸ—ï¸ Architecture

The FMAA ecosystem follows a federated microservices architecture:

1. **Agent Factory**: Central registry for all agents
2. **Specialized Agents**: Independent AI service agents
3. **Real-time Coordination**: Event-driven communication
4. **Multi-tenant Database**: Secure data isolation
5. **Serverless Functions**: Scalable API endpoints

## ðŸ“ˆ Performance

- **Response Time**: < 200ms for most operations
- **Scalability**: Auto-scaling serverless functions
- **Availability**: 99.9% uptime target
- **Monitoring**: Real-time performance metrics

---

Built with â¤ï¸ by the FMAA Team
