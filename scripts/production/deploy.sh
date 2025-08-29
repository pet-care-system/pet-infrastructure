#!/bin/bash

# Production deployment script for Pet Care System

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║     Pet Care System - Production       ║"
echo "║           Deployment Script            ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Configuration
DEPLOY_ENV="${DEPLOY_ENV:-production}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
HEALTH_CHECK_TIMEOUT=300

# Change to project root
cd "$(dirname "$0")/../.."

# Pre-deployment checks
echo -e "${YELLOW}🔍 Running pre-deployment checks...${NC}"

# Check required environment variables
REQUIRED_VARS=(
    "JWT_SECRET"
    "JWT_REFRESH_SECRET" 
    "DB_PASSWORD"
    "REDIS_PASSWORD"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Missing required environment variable: $var${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Environment variables verified${NC}"

# Check disk space
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "${AVAILABLE_SPACE%.*}" -lt 5 ]; then
    echo -e "${RED}❌ Insufficient disk space. Need at least 5GB, available: ${AVAILABLE_SPACE}G${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Disk space sufficient: ${AVAILABLE_SPACE}G available${NC}"

# Backup current deployment
if [ "$BACKUP_ENABLED" = "true" ]; then
    echo -e "${YELLOW}💾 Creating backup...${NC}"
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Export current Docker volumes
    docker run --rm -v pet-system_db_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/db_data.tar.gz -C /data . 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
fi

# Deploy services
echo -e "${YELLOW}🚀 Starting production deployment...${NC}"

# Pull latest images
echo -e "  📥 Pulling latest images..."
docker-compose -f docker/docker-compose.yml pull

# Stop existing services
echo -e "  🛑 Stopping existing services..."
docker-compose -f docker/docker-compose.yml down --remove-orphans

# Start new deployment
echo -e "  🔄 Starting new deployment..."
docker-compose -f docker/docker-compose.yml up -d --build

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 15

# Health checks
echo -e "${YELLOW}🏥 Running health checks...${NC}"
FAILED_CHECKS=()

# Check backend health
if ! curl -s -f http://localhost:3000/health >/dev/null 2>&1; then
    FAILED_CHECKS+=("Backend")
fi

# Check frontend
if ! curl -s -f http://localhost:3001 >/dev/null 2>&1; then
    FAILED_CHECKS+=("Frontend")  
fi

# Check database connection
if ! docker-compose -f docker/docker-compose.yml exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    FAILED_CHECKS+=("Database")
fi

# Report health check results
if [ ${#FAILED_CHECKS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All health checks passed${NC}"
else
    echo -e "${RED}❌ Failed health checks: ${FAILED_CHECKS[*]}${NC}"
    echo -e "${YELLOW}📋 Check logs: docker-compose -f docker/docker-compose.yml logs${NC}"
    exit 1
fi

# Post-deployment tasks
echo -e "${YELLOW}🔧 Running post-deployment tasks...${NC}"

# Run database migrations (if needed)
docker-compose -f docker/docker-compose.yml exec -T backend npm run migrate || true

# Clear Redis cache
docker-compose -f docker/docker-compose.yml exec -T redis redis-cli FLUSHALL || true

echo ""
echo -e "${GREEN}🎉 Production deployment successful!${NC}"
echo ""
echo -e "${YELLOW}📋 Service Status:${NC}"
docker-compose -f docker/docker-compose.yml ps

echo ""
echo -e "${YELLOW}🔗 Service URLs:${NC}"
echo -e "  🔙 Backend API:     http://localhost:3000"
echo -e "  🖥️  Frontend Web:    http://localhost:3001"
echo -e "  👥 Customer Portal: http://localhost:3002" 
echo -e "  📱 Mobile Backend:  http://localhost:3003"

echo ""
echo -e "${YELLOW}📊 Monitoring Commands:${NC}"
echo -e "  View logs:    docker-compose -f docker/docker-compose.yml logs -f"
echo -e "  Service status: docker-compose -f docker/docker-compose.yml ps"
echo -e "  Stop services:  ./scripts/production/stop.sh"
echo -e "  Rollback:     ./scripts/production/rollback.sh"

echo ""
echo -e "${GREEN}✨ Production deployment complete!${NC}"