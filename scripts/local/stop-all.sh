#!/bin/bash

# Stop all local Pet Care System services

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🛑 Stopping Pet Care System services...${NC}"

# Kill processes on known ports
PORTS=(3000 3001 3002 3003 8000)

for port in "${PORTS[@]}"; do
    PID=$(lsof -ti:$port 2>/dev/null || echo "")
    if [ -n "$PID" ]; then
        echo -e "  Killing process on port $port (PID: $PID)"
        kill -9 $PID 2>/dev/null || true
    else
        echo -e "  No process found on port $port"
    fi
done

# Kill Node.js processes related to pet services
echo -e "  Killing remaining Node.js processes..."
pkill -f "pet-" 2>/dev/null || true
pkill -f "npm run dev" 2>/dev/null || true
pkill -f "npm start" 2>/dev/null || true

echo -e "${GREEN}✅ All services stopped${NC}"