#!/bin/bash

# Server environment setup script
# Prepares a fresh Ubuntu server for Pet Care System deployment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
REMOTE_USER="rental-app"
REMOTE_HOST="107.150.27.138"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║      Pet Care System - Server Setup    ║"
echo "║         Target: $REMOTE_HOST          ║"  
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Function to run commands on remote server
run_remote() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "$1"
}

# Check SSH connectivity
echo -e "${YELLOW}🔍 Testing SSH connection...${NC}"
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "echo 'Connection successful'" >/dev/null 2>&1; then
    echo -e "${RED}❌ SSH connection failed${NC}"
    echo -e "${BLUE}💡 Please ensure:${NC}"
    echo -e "   • SSH key exists: $SSH_KEY"
    echo -e "   • Server is accessible: $REMOTE_HOST"
    echo -e "   • User has sudo privileges: $REMOTE_USER"
    exit 1
fi

echo -e "${GREEN}✅ SSH connection successful${NC}"

# System information
echo -e "${YELLOW}📊 Server information:${NC}"
run_remote "echo '  OS:' \$(lsb_release -d | cut -f2)"
run_remote "echo '  Kernel:' \$(uname -r)"
run_remote "echo '  CPU:' \$(nproc) cores"
run_remote "echo '  Memory:' \$(free -h | awk '/^Mem:/ {print \$2}')"
run_remote "echo '  Disk:' \$(df -h / | awk 'NR==2 {print \$4}') free"

echo ""

# Update system
echo -e "${YELLOW}🔄 Updating system packages...${NC}"
run_remote "sudo apt update && sudo apt upgrade -y"

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"

echo -e "  Installing Docker..."
run_remote "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"

echo -e "  Installing Docker Compose..."
run_remote "sudo apt install -y docker-compose-plugin"

echo -e "  Installing development tools..."
run_remote "sudo apt install -y git curl wget unzip htop tree"

echo -e "  Installing Node.js..."
run_remote "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
run_remote "sudo apt install -y nodejs"

echo -e "  Installing nginx (for reverse proxy)..."
run_remote "sudo apt install -y nginx"

echo -e "  Installing certbot (for SSL certificates)..."
run_remote "sudo apt install -y certbot python3-certbot-nginx"

# Configure Docker
echo -e "${YELLOW}🐳 Configuring Docker...${NC}"
run_remote "sudo systemctl start docker"
run_remote "sudo systemctl enable docker"
run_remote "sudo usermod -aG docker $REMOTE_USER"

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
run_remote "sudo ufw --force reset"
run_remote "sudo ufw default deny incoming"
run_remote "sudo ufw default allow outgoing"
run_remote "sudo ufw allow ssh"
run_remote "sudo ufw allow 80/tcp"   # HTTP
run_remote "sudo ufw allow 443/tcp"  # HTTPS
run_remote "sudo ufw allow 3000/tcp" # Backend
run_remote "sudo ufw allow 3001/tcp" # Frontend
run_remote "sudo ufw allow 3002/tcp" # Portal
run_remote "sudo ufw allow 3003/tcp" # Mobile
run_remote "sudo ufw --force enable"

# Create project structure
echo -e "${YELLOW}📁 Creating project structure...${NC}"
run_remote "mkdir -p /home/$REMOTE_USER/pet-system"
run_remote "mkdir -p /home/$REMOTE_USER/pet-system/logs"
run_remote "mkdir -p /home/$REMOTE_USER/pet-system/backups"
run_remote "mkdir -p /home/$REMOTE_USER/pet-system/data"

# Create environment file template
echo -e "${YELLOW}⚙️ Creating environment template...${NC}"

ENV_TEMPLATE="# Pet Care System Environment Configuration
# Copy this to .env and update values

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=petcare
DB_USER=postgres
DB_PASSWORD=CHANGE_THIS_STRONG_PASSWORD

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_THIS_REDIS_PASSWORD

# JWT Configuration
JWT_SECRET=CHANGE_THIS_TO_A_VERY_LONG_RANDOM_STRING
JWT_REFRESH_SECRET=CHANGE_THIS_TO_ANOTHER_LONG_RANDOM_STRING
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Service Configuration
BACKEND_PORT=3000
FRONTEND_PORT=3001
PORTAL_PORT=3002
MOBILE_PORT=3003

# Environment
NODE_ENV=production
LOG_LEVEL=info

# Email Configuration (optional)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=

# External API Keys (if needed)
WEATHER_API_KEY=
NOTIFICATION_API_KEY=
"

run_remote "cat > /home/$REMOTE_USER/pet-system/.env.template << 'EOF'
$ENV_TEMPLATE
EOF"

# Create nginx configuration
echo -e "${YELLOW}🌐 Creating nginx configuration...${NC}"

NGINX_CONFIG="# Pet Care System Nginx Configuration
server {
    listen 80;
    server_name $REMOTE_HOST;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $REMOTE_HOST;
    
    # SSL Configuration (will be configured by certbot)
    # ssl_certificate /etc/letsencrypt/live/$REMOTE_HOST/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$REMOTE_HOST/privkey.pem;
    
    # Frontend (main app)
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Customer Portal
    location /portal/ {
        proxy_pass http://localhost:3002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Mobile API
    location /mobile/ {
        proxy_pass http://localhost:3003/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
"

run_remote "sudo tee /etc/nginx/sites-available/pet-system << 'EOF'
$NGINX_CONFIG
EOF"

run_remote "sudo ln -sf /etc/nginx/sites-available/pet-system /etc/nginx/sites-enabled/"
run_remote "sudo nginx -t && sudo systemctl restart nginx"

# Create systemctl services for automatic startup
echo -e "${YELLOW}🚀 Creating system services...${NC}"

SYSTEMD_SERVICE="[Unit]
Description=Pet Care System
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/home/$REMOTE_USER/pet-system
ExecStart=/usr/bin/docker-compose -f docker/docker-compose.yml up -d
ExecStop=/usr/bin/docker-compose -f docker/docker-compose.yml down
User=$REMOTE_USER

[Install]
WantedBy=multi-user.target
"

run_remote "sudo tee /etc/systemd/system/pet-system.service << 'EOF'
$SYSTEMD_SERVICE
EOF"

run_remote "sudo systemctl daemon-reload"
run_remote "sudo systemctl enable pet-system.service"

# Create backup script
echo -e "${YELLOW}💾 Creating backup script...${NC}"

BACKUP_SCRIPT="#!/bin/bash
# Daily backup script for Pet Care System

BACKUP_DIR=\"/home/$REMOTE_USER/pet-system/backups\"
DATE=\$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p \"\$BACKUP_DIR\"

# Backup database
docker exec pet-system_db_1 pg_dump -U postgres petcare > \"\$BACKUP_DIR/db_\$DATE.sql\"

# Backup uploaded files
tar -czf \"\$BACKUP_DIR/files_\$DATE.tar.gz\" /home/$REMOTE_USER/pet-system/data/ 2>/dev/null || true

# Keep only last 7 days of backups
find \"\$BACKUP_DIR\" -type f -mtime +7 -delete

echo \"Backup completed: \$DATE\"
"

run_remote "tee /home/$REMOTE_USER/pet-system/backup.sh << 'EOF'
$BACKUP_SCRIPT
EOF"

run_remote "chmod +x /home/$REMOTE_USER/pet-system/backup.sh"

# Add backup to crontab
run_remote "echo '0 2 * * * /home/$REMOTE_USER/pet-system/backup.sh >> /home/$REMOTE_USER/pet-system/logs/backup.log 2>&1' | crontab -"

# Installation summary
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║          Server Setup Complete!        ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}✅ Installed components:${NC}"
echo -e "  • Docker & Docker Compose"
echo -e "  • Node.js 18"
echo -e "  • Nginx reverse proxy"
echo -e "  • Certbot for SSL"
echo -e "  • UFW firewall configured"
echo -e "  • System service for auto-start"
echo -e "  • Daily backup script"

echo ""
echo -e "${YELLOW}🔧 Next steps:${NC}"
echo -e "  1. Update environment variables:"
echo -e "     ssh $REMOTE_USER@$REMOTE_HOST 'nano /home/$REMOTE_USER/pet-system/.env.template'"
echo -e "     ssh $REMOTE_USER@$REMOTE_HOST 'cp /home/$REMOTE_USER/pet-system/.env.template /home/$REMOTE_USER/pet-system/.env'"
echo ""
echo -e "  2. Deploy the application:"
echo -e "     ./scripts/remote/deploy-to-server.sh"
echo ""
echo -e "  3. Setup SSL certificate (after deployment):"
echo -e "     ssh $REMOTE_USER@$REMOTE_HOST 'sudo certbot --nginx -d $REMOTE_HOST'"

echo ""
echo -e "${GREEN}🎉 Server is ready for Pet Care System deployment!${NC}"