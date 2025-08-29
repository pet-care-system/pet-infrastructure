# Remote Server Deployment Guide

Complete guide for deploying Pet Care System to a remote server.

## 🎯 Overview

This guide covers deploying the Pet Care System to a remote Ubuntu server using Docker containers with nginx as a reverse proxy.

**Target Server**: `rental-app@107.150.27.138`

## 📋 Prerequisites

### Local Requirements
- SSH access to the remote server
- SSH key configured (recommended: `~/.ssh/id_rsa`)
- All Pet Care System repositories cloned locally:
  - `pet-backend`
  - `pet-frontend` 
  - `pet-customer-portal`
  - `pet-mobile`
  - `pet-shared`

### Server Requirements
- Ubuntu 20.04+ or similar Linux distribution
- Sudo privileges for the deployment user
- At least 4GB RAM
- At least 20GB disk space
- Internet connectivity

## 🚀 Deployment Process

### Step 1: Server Environment Setup

First, prepare the server environment:

```bash
# Run the server setup script
./scripts/remote/setup-server.sh
```

This script will:
- ✅ Install Docker & Docker Compose
- ✅ Install Node.js 18
- ✅ Configure nginx reverse proxy  
- ✅ Setup firewall rules
- ✅ Create system services
- ✅ Setup automated backups

### Step 2: Configure Environment

SSH to the server and configure environment variables:

```bash
# Connect to server
ssh rental-app@107.150.27.138

# Edit environment configuration
nano /home/rental-app/pet-system/.env.template

# Copy to active environment file
cp /home/rental-app/pet-system/.env.template /home/rental-app/pet-system/.env
```

**Important environment variables to update**:
```bash
# Strong passwords
DB_PASSWORD=your-strong-database-password
REDIS_PASSWORD=your-redis-password

# JWT secrets (use long random strings)
JWT_SECRET=your-very-long-random-jwt-secret-key
JWT_REFRESH_SECRET=your-refresh-token-secret-key

# Optional: Email/SMS configuration
SMTP_HOST=your-smtp-server
SMTP_USER=your-email
SMTP_PASS=your-email-password
```

### Step 3: Deploy Application

Run the deployment script:

```bash
# Deploy to remote server
./scripts/remote/deploy-to-server.sh
```

This will:
- ✅ Copy all infrastructure files
- ✅ Deploy all service repositories
- ✅ Build Docker images
- ✅ Start all services
- ✅ Run health checks
- ✅ Configure firewall

### Step 4: SSL Certificate (Optional)

Setup HTTPS with Let's Encrypt:

```bash
# SSH to server
ssh rental-app@107.150.27.138

# Generate SSL certificate
sudo certbot --nginx -d 107.150.27.138

# Verify SSL renewal
sudo certbot renew --dry-run
```

## 🌐 Service URLs

After successful deployment, services will be available at:

- **Frontend Web**: http://107.150.27.138:3001 (or https with SSL)
- **Backend API**: http://107.150.27.138:3000
- **Customer Portal**: http://107.150.27.138:3002
- **Mobile Backend**: http://107.150.27.138:3003

With nginx proxy (after SSL setup):
- **Main Application**: https://107.150.27.138/
- **API Endpoints**: https://107.150.27.138/api/
- **Customer Portal**: https://107.150.27.138/portal/
- **Mobile API**: https://107.150.27.138/mobile/

## 📊 Management Commands

### View Service Status
```bash
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose ps'
```

### View Logs
```bash
# All services
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose logs -f'

# Specific service
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose logs -f backend'
```

### Restart Services
```bash
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose restart'
```

### Stop Services
```bash
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose down'
```

### Update Deployment
```bash
# Run from local machine
./scripts/remote/update-server.sh
```

## 🛠️ Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection
ssh -v rental-app@107.150.27.138

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Service Not Starting

```bash
# Check logs
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose logs [service-name]'

# Check Docker status
ssh rental-app@107.150.27.138 'sudo systemctl status docker'

# Restart Docker
ssh rental-app@107.150.27.138 'sudo systemctl restart docker'
```

### Database Issues

```bash
# Check database container
ssh rental-app@107.150.27.138 'docker exec -it pet-system_db_1 psql -U postgres -d petcare'

# Reset database (WARNING: Data loss)
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose down && docker volume rm pet-system_db_data && docker-compose up -d'
```

### Firewall Issues

```bash
# Check firewall status
ssh rental-app@107.150.27.138 'sudo ufw status'

# Open additional ports if needed
ssh rental-app@107.150.27.138 'sudo ufw allow [PORT]/tcp'
```

### Nginx Issues

```bash
# Check nginx status
ssh rental-app@107.150.27.138 'sudo systemctl status nginx'

# Test nginx configuration
ssh rental-app@107.150.27.138 'sudo nginx -t'

# Restart nginx
ssh rental-app@107.150.27.138 'sudo systemctl restart nginx'
```

## 💾 Backup & Recovery

### Manual Backup
```bash
ssh rental-app@107.150.27.138 '/home/rental-app/pet-system/backup.sh'
```

### Restore from Backup
```bash
# List available backups
ssh rental-app@107.150.27.138 'ls -la /home/rental-app/pet-system/backups/'

# Restore database (replace DATE with actual backup date)
ssh rental-app@107.150.27.138 'docker exec -i pet-system_db_1 psql -U postgres -d petcare < /home/rental-app/pet-system/backups/db_DATE.sql'
```

### Automated Backups

Backups are automatically created daily at 2 AM via crontab. Backups older than 7 days are automatically deleted.

## 🔄 Update Process

1. **Local Development**: Make changes to your services locally
2. **Test**: Test changes in local environment
3. **Deploy**: Run update script
   ```bash
   ./scripts/remote/update-server.sh
   ```

## 📈 Monitoring

### Resource Usage
```bash
# Check system resources
ssh rental-app@107.150.27.138 'htop'

# Check disk usage
ssh rental-app@107.150.27.138 'df -h'

# Check Docker resource usage
ssh rental-app@107.150.27.138 'docker stats'
```

### Log Monitoring
```bash
# Watch logs in real-time
ssh rental-app@107.150.27.138 'cd /home/rental-app/pet-system && docker-compose logs -f --tail=100'

# Check nginx access logs
ssh rental-app@107.150.27.138 'sudo tail -f /var/log/nginx/access.log'
```

## 🔒 Security Considerations

1. **Environment Variables**: Never commit `.env` files with production secrets
2. **SSL/TLS**: Always use HTTPS in production
3. **Firewall**: Keep only necessary ports open
4. **Updates**: Regularly update system packages and Docker images
5. **Backups**: Verify backups are working and test restoration
6. **Access**: Limit SSH access and use key-based authentication

## 📞 Support

For deployment issues:

1. Check this troubleshooting guide
2. Review service logs 
3. Verify server resources and connectivity
4. Check Docker and nginx status

## 🎉 Success Checklist

After deployment, verify:

- [ ] All services start without errors
- [ ] Health check endpoints respond correctly
- [ ] Frontend loads in browser
- [ ] API endpoints are accessible
- [ ] Database is connected and accessible
- [ ] SSL certificate is configured (if used)
- [ ] Firewall allows required traffic
- [ ] Backup script is working
- [ ] System service is enabled for auto-start