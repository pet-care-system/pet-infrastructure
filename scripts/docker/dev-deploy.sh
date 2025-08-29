#!/bin/bash

# Docker development deployment script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   Pet Care System - Docker Development ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Change to project root
cd "$(dirname "$0")/../.."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Building and starting development environment...${NC}"

# Use development Docker Compose file
docker-compose -f docker/docker-compose.local.yml down --remove-orphans
docker-compose -f docker/docker-compose.local.yml build
docker-compose -f docker/docker-compose.local.yml up -d

echo ""
echo -e "${GREEN}✅ Development environment started!${NC}"
echo ""
echo -e "${YELLOW}📋 Services:${NC}"
echo -e "  🔙 Backend:    http://localhost:3000"
echo -e "  🖥️  Frontend:   http://localhost:3001"
echo -e "  💾 Database:   localhost:5432 (PostgreSQL)"
echo -e "  📊 Redis:      localhost:6379"
echo ""
echo -e "${YELLOW}🔍 Useful commands:${NC}"
echo -e "  View logs:     docker-compose -f docker/docker-compose.local.yml logs -f"
echo -e "  Stop services: ./scripts/docker/stop.sh"
echo -e "  Restart:       ./scripts/docker/restart.sh"