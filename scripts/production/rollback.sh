#!/bin/bash

# Production rollback script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Pet Care System - Production Rollback${NC}"
echo ""

# Change to project root
cd "$(dirname "$0")/../.."

# Find latest backup
BACKUP_DIR=$(ls -1t backups/ 2>/dev/null | head -n1)

if [ -z "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ No backups found${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Found backup: $BACKUP_DIR${NC}"
echo -e "${YELLOW}⚠️  This will stop current services and restore from backup${NC}"
echo ""

read -p "Continue with rollback? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Rollback cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}🛑 Stopping current services...${NC}"
docker-compose -f docker/docker-compose.yml down

echo -e "${YELLOW}📥 Restoring backup...${NC}"
if [ -f "backups/$BACKUP_DIR/db_data.tar.gz" ]; then
    docker run --rm -v pet-system_db_data:/data -v $(pwd)/backups/$BACKUP_DIR:/backup alpine tar xzf /backup/db_data.tar.gz -C /data
fi

echo -e "${YELLOW}🚀 Starting services...${NC}"
docker-compose -f docker/docker-compose.yml up -d

echo -e "${GREEN}✅ Rollback complete${NC}"