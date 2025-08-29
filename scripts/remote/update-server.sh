#!/bin/bash

# Update Pet Care System on remote server

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
REMOTE_USER="rental-app"
REMOTE_HOST="107.150.27.138"
REMOTE_PATH="/home/rental-app/pet-system"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║    Pet Care System - Server Update     ║"
echo "║         Target: $REMOTE_HOST          ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Function to run commands on remote server
run_remote() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "$1"
}

# Function to copy files to remote server
copy_to_remote() {
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -r "$1" "$REMOTE_USER@$REMOTE_HOST:$2"
}

# Pre-update backup
echo -e "${YELLOW}💾 Creating backup before update...${NC}"
run_remote "cd $REMOTE_PATH && ./backup.sh"

# Stop services
echo -e "${YELLOW}🛑 Stopping services...${NC}"
run_remote "cd $REMOTE_PATH && docker-compose -f docker/docker-compose.yml down"

# Update infrastructure
echo -e "${YELLOW}📦 Updating infrastructure files...${NC}"
cd "$(dirname "$0")/../.."
copy_to_remote "." "$REMOTE_PATH/"

# Update services if they exist locally
BASE_PATH="/Users/newdroid/Documents/project"
REPOS=("pet-backend" "pet-frontend" "pet-customer-portal" "pet-mobile" "pet-shared")

echo -e "${YELLOW}🔄 Updating services...${NC}"
for repo in "${REPOS[@]}"; do
    if [ -d "$BASE_PATH/$repo" ]; then
        echo -e "  Updating $repo..."
        copy_to_remote "$BASE_PATH/$repo" "$REMOTE_PATH/"
        run_remote "cd $REMOTE_PATH/$repo && npm install --production"
    fi
done

# Rebuild and restart services
echo -e "${YELLOW}🔨 Rebuilding services...${NC}"
run_remote "cd $REMOTE_PATH && docker-compose -f docker/docker-compose.yml build"

echo -e "${YELLOW}🚀 Starting services...${NC}"
run_remote "cd $REMOTE_PATH && docker-compose -f docker/docker-compose.yml up -d"

# Wait and health check
echo -e "${YELLOW}⏳ Waiting for services...${NC}"
sleep 30

echo -e "${YELLOW}🏥 Health checks...${NC}"
HEALTH_CHECKS=("3000:/health:Backend" "3001/:Frontend" "3002/:Portal" "3003/health:Mobile")

for check in "${HEALTH_CHECKS[@]}"; do
    IFS=":" read -r port path service <<< "$check"
    if run_remote "curl -s -f http://localhost:$port$path >/dev/null 2>&1"; then
        echo -e "  ✅ $service - Healthy"
    else
        echo -e "  ❌ $service - Not responding"
    fi
done

echo -e "${GREEN}✅ Update complete!${NC}"