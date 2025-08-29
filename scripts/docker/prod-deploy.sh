#!/bin/bash

# Docker production deployment script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   Pet Care System - Production Deploy  ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Change to project root
cd "$(dirname "$0")/../.."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check environment variables
echo -e "${YELLOW}🔍 Checking environment variables...${NC}"
REQUIRED_VARS=("JWT_SECRET" "DB_PASSWORD")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Missing required environment variable: $var${NC}"
        exit 1
    else
        echo -e "  ✅ $var is set"
    fi
done

echo -e "${YELLOW}🔧 Building production images...${NC}"

# Build and deploy
docker-compose -f docker/docker-compose.yml down --remove-orphans
docker-compose -f docker/docker-compose.yml build --no-cache
docker-compose -f docker/docker-compose.yml up -d

echo ""
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Health checks
echo -e "${YELLOW}🏥 Running health checks...${NC}"
HEALTH_URLS=("http://localhost:3000/health" "http://localhost:3001")
for url in "${HEALTH_URLS[@]}"; do
    if curl -s -f "$url" >/dev/null; then
        echo -e "  ✅ $url - Healthy"
    else
        echo -e "  ❌ $url - Not responding"
    fi
done

echo ""
echo -e "${GREEN}🎉 Production deployment complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Services:${NC}"
echo -e "  🔙 Backend:    http://localhost:3000"
echo -e "  🖥️  Frontend:   http://localhost:3001"
echo -e "  📱 Mobile:     http://localhost:3003"
echo -e "  👥 Portal:     http://localhost:3002"
echo ""
echo -e "${YELLOW}📊 Monitoring:${NC}"
echo -e "  Logs:          docker-compose -f docker/docker-compose.yml logs -f"
echo -e "  Status:        docker-compose -f docker/docker-compose.yml ps"
echo -e "  Stop:          ./scripts/docker/stop.sh"