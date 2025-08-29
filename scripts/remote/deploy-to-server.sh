#!/bin/bash

# Remote server deployment script for Pet Care System
# Deploys the entire system to a remote server via SSH

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
echo "║    Pet Care System - Remote Deploy     ║"
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

# Pre-deployment checks
echo -e "${YELLOW}🔍 Running pre-deployment checks...${NC}"

# Check SSH connectivity
echo -e "  Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "echo 'Connection successful'" >/dev/null 2>&1; then
    echo -e "${RED}❌ SSH connection failed${NC}"
    echo -e "${BLUE}💡 Please check:${NC}"
    echo -e "   • SSH key exists: $SSH_KEY"
    echo -e "   • Server is accessible: $REMOTE_HOST"
    echo -e "   • User has correct permissions: $REMOTE_USER"
    exit 1
fi

echo -e "${GREEN}✅ SSH connection successful${NC}"

# Check if Git repositories exist
echo -e "${YELLOW}📋 Required repositories:${NC}"
REPOS=("pet-backend" "pet-frontend" "pet-customer-portal" "pet-mobile" "pet-shared")
BASE_PATH="/Users/newdroid/Documents/project"

missing_repos=()
for repo in "${REPOS[@]}"; do
    if [ -d "$BASE_PATH/$repo" ]; then
        echo -e "  ✅ $repo - Found locally"
    else
        echo -e "  ❌ $repo - Missing locally"
        missing_repos+=("$repo")
    fi
done

if [ ${#missing_repos[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing repositories: ${missing_repos[*]}${NC}"
    echo -e "${BLUE}💡 Please clone missing repositories first${NC}"
    exit 1
fi

# Setup remote environment
echo -e "${YELLOW}🔧 Setting up remote environment...${NC}"

echo -e "  Creating project directory..."
run_remote "mkdir -p $REMOTE_PATH"

echo -e "  Installing required packages..."
run_remote "sudo apt update && sudo apt install -y docker.io docker-compose git nodejs npm"

echo -e "  Starting Docker service..."
run_remote "sudo systemctl start docker && sudo systemctl enable docker"

echo -e "  Adding user to docker group..."
run_remote "sudo usermod -aG docker $REMOTE_USER" || true

echo -e "${GREEN}✅ Remote environment ready${NC}"

# Deploy infrastructure
echo -e "${YELLOW}📦 Deploying infrastructure...${NC}"
cd "$(dirname "$0")/../.."

echo -e "  Copying infrastructure files..."
copy_to_remote "." "$REMOTE_PATH/"

# Deploy each service
echo -e "${YELLOW}🚀 Deploying services...${NC}"

for repo in "${REPOS[@]}"; do
    if [ -d "$BASE_PATH/$repo" ]; then
        echo -e "${BLUE}Deploying $repo...${NC}"
        
        # Copy service files
        copy_to_remote "$BASE_PATH/$repo" "$REMOTE_PATH/"
        
        # Build and prepare service
        run_remote "cd $REMOTE_PATH/$repo && npm install --production"
        
        echo -e "  ✅ $repo deployed"
    fi
done

# Create environment file
echo -e "${YELLOW}⚙️ Creating environment configuration...${NC}"

ENV_CONTENT="# Pet Care System Environment Configuration
# Generated on $(date)

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=petcare
DB_USER=postgres
DB_PASSWORD=\${DB_PASSWORD:-secretpassword}

# Redis Configuration  
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=\${REDIS_PASSWORD:-redispassword}

# JWT Configuration
JWT_SECRET=\${JWT_SECRET:-your-super-secret-jwt-key-change-in-production}
JWT_REFRESH_SECRET=\${JWT_REFRESH_SECRET:-your-refresh-secret-key}
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Service Ports
BACKEND_PORT=3000
FRONTEND_PORT=3001
PORTAL_PORT=3002
MOBILE_PORT=3003

# Environment
NODE_ENV=production
"

run_remote "cat > $REMOTE_PATH/.env << 'EOF'
$ENV_CONTENT
EOF"

# Deploy with Docker
echo -e "${YELLOW}🐳 Starting Docker deployment...${NC}"

run_remote "cd $REMOTE_PATH && docker-compose -f docker/docker-compose.yml down --remove-orphans || true"
run_remote "cd $REMOTE_PATH && docker-compose -f docker/docker-compose.yml build"
run_remote "cd $REMOTE_PATH && docker-compose -f docker/docker-compose.yml up -d"

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 30

# Health checks
echo -e "${YELLOW}🏥 Running health checks...${NC}"

HEALTH_CHECKS=(
    "3000:/health:Backend API"
    "3001/:Frontend Web"
    "3002/:Customer Portal" 
    "3003/health:Mobile Backend"
)

failed_checks=()
for check in "${HEALTH_CHECKS[@]}"; do
    IFS=":" read -r port path service <<< "$check"
    
    if run_remote "curl -s -f http://localhost:$port$path >/dev/null 2>&1"; then
        echo -e "  ✅ $service (port $port) - Healthy"
    else
        echo -e "  ❌ $service (port $port) - Not responding"
        failed_checks+=("$service")
    fi
done

# Setup firewall rules
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
run_remote "sudo ufw allow 22/tcp"  # SSH
run_remote "sudo ufw allow 3000/tcp"  # Backend
run_remote "sudo ufw allow 3001/tcp"  # Frontend
run_remote "sudo ufw allow 3002/tcp"  # Portal
run_remote "sudo ufw allow 3003/tcp"  # Mobile
run_remote "sudo ufw --force enable" || true

# Final status
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ ${#failed_checks[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 Deployment successful!${NC}"
else
    echo -e "${YELLOW}⚠️  Deployment completed with warnings${NC}"
    echo -e "${YELLOW}Failed services: ${failed_checks[*]}${NC}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Display service URLs
echo -e "${YELLOW}🔗 Service URLs:${NC}"
echo -e "  🔙 Backend API:     http://$REMOTE_HOST:3000"
echo -e "  🖥️  Frontend Web:    http://$REMOTE_HOST:3001"
echo -e "  👥 Customer Portal: http://$REMOTE_HOST:3002"
echo -e "  📱 Mobile Backend:  http://$REMOTE_HOST:3003"
echo ""

# Management commands
echo -e "${YELLOW}📊 Management Commands:${NC}"
echo -e "  View logs:     ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_PATH && docker-compose logs -f'"
echo -e "  Restart:       ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_PATH && docker-compose restart'"
echo -e "  Stop:          ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_PATH && docker-compose down'"
echo -e "  Update:        ./scripts/remote/update-server.sh"
echo ""

echo -e "${GREEN}✨ Remote deployment complete!${NC}"
echo -e "${BLUE}📖 For troubleshooting, see: docs/deployment/REMOTE_DEPLOYMENT.md${NC}"