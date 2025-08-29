#!/bin/bash

# Stop Docker services

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🛑 Stopping Docker services...${NC}"

# Change to project root
cd "$(dirname "$0")/../.."

# Stop all compose files
docker-compose -f docker/docker-compose.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker/docker-compose.local.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker/docker-compose.simple.yml down --remove-orphans 2>/dev/null || true

echo -e "${GREEN}✅ All Docker services stopped${NC}"