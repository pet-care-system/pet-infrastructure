#!/bin/bash

# Local development startup script for all services
# Starts all Pet Care System services locally

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║     Pet Care System - Local Startup    ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Configuration
BASE_PATH="/Users/newdroid/Documents/project"
SERVICES=("pet-backend" "pet-frontend" "pet-customer-portal" "pet-mobile")

# Check if directories exist
echo -e "${YELLOW}🔍 Checking service directories...${NC}"
for service in "${SERVICES[@]}"; do
    if [ -d "$BASE_PATH/$service" ]; then
        echo -e "  ✅ $service - Found"
    else
        echo -e "  ❌ $service - Not found at $BASE_PATH/$service"
    fi
done

echo ""
echo -e "${YELLOW}🚀 Starting services...${NC}"
echo ""

# Start Backend
echo -e "${BLUE}Starting Backend (port 3000)...${NC}"
cd "$BASE_PATH/pet-backend"
npm run dev &
BACKEND_PID=$!
sleep 3

# Start Frontend
echo -e "${BLUE}Starting Frontend (port 3001)...${NC}"
cd "$BASE_PATH/pet-frontend" 
npm run dev &
FRONTEND_PID=$!
sleep 3

# Start Customer Portal
echo -e "${BLUE}Starting Customer Portal (port 3002)...${NC}"
cd "$BASE_PATH/pet-customer-portal"
npm run dev &
PORTAL_PID=$!
sleep 3

# Start Mobile Backend
echo -e "${BLUE}Starting Mobile Backend (port 3003)...${NC}"
cd "$BASE_PATH/pet-mobile/backend"
npm start &
MOBILE_PID=$!

echo ""
echo -e "${GREEN}✅ All services started!${NC}"
echo ""
echo -e "${YELLOW}📋 Service URLs:${NC}"
echo -e "  🔙 Backend:         http://localhost:3000"
echo -e "  🖥️  Frontend:        http://localhost:3001" 
echo -e "  👥 Customer Portal: http://localhost:3002"
echo -e "  📱 Mobile Backend:  http://localhost:3003"
echo ""
echo -e "${YELLOW}📝 Process IDs:${NC}"
echo -e "  Backend: $BACKEND_PID"
echo -e "  Frontend: $FRONTEND_PID" 
echo -e "  Portal: $PORTAL_PID"
echo -e "  Mobile: $MOBILE_PID"
echo ""
echo -e "${BLUE}💡 To stop all services: ./scripts/local/stop-all.sh${NC}"

# Keep script running
wait