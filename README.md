# Pet Care System Infrastructure

Infrastructure files, deployment guides, and automation scripts for the Pet Care System.

## 📁 Project Structure

```
pet-infrastructure/
├── docs/                    # Documentation
│   ├── deployment/         # Deployment guides
│   └── architecture/       # System architecture docs
├── scripts/                # Deployment and utility scripts
│   ├── local/             # Local development scripts
│   ├── docker/            # Docker deployment scripts
│   └── production/        # Production deployment scripts
├── docker/                 # Docker configurations
└── api-test.html          # API testing interface
```

## 🚀 Quick Start

### Local Development
```bash
# Start all services locally
./scripts/local/start-all.sh

# Stop all services
./scripts/local/stop-all.sh
```

### Docker Deployment
```bash
# Development environment
./scripts/docker/dev-deploy.sh

# Production environment
./scripts/docker/prod-deploy.sh

# Stop services
./scripts/docker/stop.sh
```

### Remote Server Deployment
```bash
# Setup server environment (run once)
./scripts/remote/setup-server.sh

# Deploy to remote server
./scripts/remote/deploy-to-server.sh

# Update remote deployment
./scripts/remote/update-server.sh
```

## 📚 Documentation

- [Deployment Guide](docs/deployment/README.md) - Complete deployment instructions
- [Remote Deployment](docs/deployment/REMOTE_DEPLOYMENT.md) - Remote server deployment guide
- [Architecture Overview](docs/architecture/DEPLOYMENT_ARCHITECTURE.md) - System architecture documentation
- [Docker Guide](docs/deployment/DOCKER_GUIDE.md) - Docker deployment guide

## 🔗 Related Repositories

- [pet-backend](https://github.com/pet-care-system/pet-backend) - Backend API service
- [pet-frontend](https://github.com/pet-care-system/pet-frontend) - Web frontend application  
- [pet-mobile](https://github.com/pet-care-system/pet-mobile) - Mobile application
- [pet-customer-portal](https://github.com/pet-care-system/pet-customer-portal) - Customer portal
- [pet-shared](https://github.com/pet-care-system/pet-shared) - Shared components and utilities

## 🛠️ Requirements

- Docker & Docker Compose
- Node.js 18+
- Git