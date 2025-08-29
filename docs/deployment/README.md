# Deployment Guide

Complete deployment instructions for the Pet Care System.

## 📖 Available Guides

- [Quick Start](QUICK_START.md) - Get started quickly
- [Docker Deployment](DOCKER_GUIDE.md) - Docker-based deployment
- [Docker Setup](DOCKER_SETUP_SUMMARY.md) - Docker setup summary
- [Docker Troubleshooting](DOCKER_TROUBLESHOOTING.md) - Common Docker issues
- [Manual Docker Guide](MANUAL_DOCKER_GUIDE.md) - Manual Docker deployment

## 🚀 Deployment Options

### 1. Local Development
Best for development and testing:
```bash
# Start all services locally
../scripts/local/start-all.sh
```

### 2. Docker Development
Containerized development environment:
```bash
# Start with Docker Compose
../scripts/docker/dev-deploy.sh
```

### 3. Production Deployment
Full production setup:
```bash
# Deploy to production
../scripts/production/deploy.sh
```

## 📋 Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Git
- 4GB+ RAM
- 10GB+ disk space