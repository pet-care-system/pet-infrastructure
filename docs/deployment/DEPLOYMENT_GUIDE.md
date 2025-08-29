# Pet Care Management System - Complete Deployment Guide

This guide provides step-by-step instructions for setting up and deploying the entire Pet Care Management System with all CI/CD pipelines.

## 📋 Prerequisites

### Development Environment
- Node.js 18+ installed
- Git configured
- Docker and Docker Compose installed
- GitHub account with organization/personal repositories

### Cloud Services (Recommended)
- **GitHub** - Source control and CI/CD
- **Vercel** - Frontend and customer portal hosting
- **Docker Hub/GitHub Container Registry** - Container images
- **PostgreSQL** - Database (AWS RDS, Google Cloud SQL, or self-hosted)
- **Redis** - Caching (AWS ElastiCache, Redis Cloud, or self-hosted)

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pet Frontend  │    │ Customer Portal │    │   Pet Mobile    │
│   (React/Vite)  │    │   (Next.js)     │    │ (React Native)  │
│                 │    │                 │    │                 │
│    Vercel       │    │    Vercel       │    │  App Stores     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                  ┌─────────────────────────┐
                  │     Pet Backend         │
                  │     (Node.js API)       │
                  │                         │
                  │  Docker Container       │
                  └─────────────────────────┘
                                 │
                  ┌─────────────────────────┐
                  │     Database            │
                  │   (PostgreSQL)          │
                  │                         │
                  │     Redis Cache         │
                  └─────────────────────────┘
```

## 🔧 Step 1: Repository Setup

### Create GitHub Repositories

1. Create 5 separate repositories:
   ```bash
   pet-backend
   pet-frontend
   pet-mobile
   pet-customer-portal
   pet-shared
   ```

2. Clone and setup each repository:
   ```bash
   # Backend
   git clone https://github.com/your-org/pet-backend.git
   cd pet-backend
   cp -r /path/to/existing/backend/* .
   
   # Frontend
   git clone https://github.com/your-org/pet-frontend.git
   cd pet-frontend
   cp -r /path/to/existing/frontend/* .
   
   # Mobile
   git clone https://github.com/your-org/pet-mobile.git
   cd pet-mobile
   cp -r /path/to/existing/mobile/* .
   
   # Customer Portal
   git clone https://github.com/your-org/pet-customer-portal.git
   cd pet-customer-portal
   cp -r /path/to/existing/customer-portal/* .
   
   # Shared Package
   git clone https://github.com/your-org/pet-shared.git
   cd pet-shared
   cp -r /path/to/existing/shared/* .
   ```

3. Copy the GitHub Actions workflows to each repository:
   ```bash
   # The workflow files are already created in:
   # - /Users/newdroid/Documents/project/pet-backend/.github/
   # - /Users/newdroid/Documents/project/pet-frontend/.github/
   # - /Users/newdroid/Documents/project/pet-mobile/.github/
   # - /Users/newdroid/Documents/project/pet-customer-portal/.github/
   # - /Users/newdroid/Documents/project/pet-shared/.github/
   ```

## 🔐 Step 2: Secrets Configuration

### GitHub Repository Secrets

For each repository, go to Settings > Secrets and variables > Actions:

#### All Repositories
```bash
CODECOV_TOKEN=<your-codecov-token>
SNYK_TOKEN=<your-snyk-token>
SLACK_WEBHOOK_URL=<your-slack-webhook>
```

#### Backend (pet-backend)
```bash
# No additional secrets needed for basic setup
# Add deployment secrets based on your infrastructure
```

#### Frontend (pet-frontend)
```bash
VERCEL_TOKEN=<your-vercel-token>
VERCEL_ORG_ID=<your-vercel-org-id>
VERCEL_PROJECT_ID=<your-vercel-project-id>
```

#### Mobile (pet-mobile)
```bash
ANDROID_KEYSTORE_BASE64=<base64-encoded-keystore>
ANDROID_KEYSTORE_PASSWORD=<keystore-password>
ANDROID_KEY_ALIAS=<key-alias>
ANDROID_KEY_PASSWORD=<key-password>
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=<service-account-json>

IOS_CERTIFICATES_P12=<base64-encoded-certificates>
IOS_CERTIFICATES_PASSWORD=<certificates-password>
APPSTORE_ISSUER_ID=<app-store-issuer-id>
APPSTORE_KEY_ID=<app-store-key-id>
APPSTORE_PRIVATE_KEY=<app-store-private-key>
```

#### Customer Portal (pet-customer-portal)
```bash
VERCEL_TOKEN=<your-vercel-token>
VERCEL_ORG_ID=<your-vercel-org-id>
VERCEL_PROJECT_ID=<your-vercel-project-id>
TEST_USER_EMAIL=<test-user-email>
TEST_USER_PASSWORD=<test-user-password>
```

#### Shared Package (pet-shared)
```bash
NPM_TOKEN=<your-npm-token>
DEPENDENCY_UPDATE_TOKEN=<github-token-for-cross-repo-updates>
```

### Environment Secrets

Create environments (development, staging, production) and add environment-specific secrets:

#### Backend Environments
```bash
# Development
DATABASE_URL=postgresql://user:pass@localhost:5432/petcare_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-jwt-secret

# Staging
DATABASE_URL=postgresql://user:pass@staging-db:5432/petcare_staging
REDIS_URL=redis://staging-redis:6379
JWT_SECRET=staging-jwt-secret

# Production
DATABASE_URL=postgresql://user:pass@prod-db:5432/petcare_production
REDIS_URL=redis://prod-redis:6379
JWT_SECRET=production-jwt-secret-very-secure
```

#### Frontend Environments
```bash
# Development
VITE_API_BASE_URL=http://localhost:3000
VITE_APP_ENV=development

# Staging
VITE_API_BASE_URL=https://api-staging.petcare.com
VITE_APP_ENV=staging

# Production
VITE_API_BASE_URL=https://api.petcare.com
VITE_APP_ENV=production
```

## 🚀 Step 3: Deploy Infrastructure

### Database Setup

#### PostgreSQL Setup
```sql
-- Create databases
CREATE DATABASE petcare_development;
CREATE DATABASE petcare_staging;
CREATE DATABASE petcare_production;

-- Create users
CREATE USER petcare_dev WITH ENCRYPTED PASSWORD 'dev_password';
CREATE USER petcare_staging WITH ENCRYPTED PASSWORD 'staging_password';
CREATE USER petcare_prod WITH ENCRYPTED PASSWORD 'secure_production_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE petcare_development TO petcare_dev;
GRANT ALL PRIVILEGES ON DATABASE petcare_staging TO petcare_staging;
GRANT ALL PRIVILEGES ON DATABASE petcare_production TO petcare_prod;
```

#### Redis Setup
```bash
# Development (local)
docker run -d --name redis-dev -p 6379:6379 redis:7

# Staging/Production
# Use managed Redis service (AWS ElastiCache, Redis Cloud, etc.)
```

### Vercel Setup

1. Install Vercel CLI:
   ```bash
   npm i -g vercel
   ```

2. Login and setup projects:
   ```bash
   vercel login
   vercel --prod  # Deploy to get project ID
   vercel org ls  # Get organization ID
   ```

3. Configure domains:
   - Frontend: `app.petcare.com`
   - Customer Portal: `customer.petcare.com`

## 📱 Step 4: Mobile App Configuration

### Android Setup

1. Generate signing keystore:
   ```bash
   keytool -genkey -v -keystore pet-mobile-release.keystore \
     -alias pet-mobile -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Convert to base64:
   ```bash
   base64 -i pet-mobile-release.keystore -o keystore-base64.txt
   ```

3. Setup Google Play Console:
   - Create app in Google Play Console
   - Generate service account JSON
   - Enable Google Play Developer API

### iOS Setup

1. Setup Apple Developer Account:
   - Enroll in Apple Developer Program
   - Create App Store Connect app
   - Generate API key

2. Export certificates:
   ```bash
   # Export from Keychain Access as .p12 file
   base64 -i certificate.p12 > certificate-base64.txt
   ```

## 🔄 Step 5: Test CI/CD Pipelines

### Test Each Repository

1. **Backend**:
   ```bash
   cd pet-backend
   git add .
   git commit -m "feat: initial CI/CD setup"
   git push origin main
   ```

2. **Frontend**:
   ```bash
   cd pet-frontend
   git add .
   git commit -m "feat: initial CI/CD setup"
   git push origin main
   ```

3. **Mobile**:
   ```bash
   cd pet-mobile
   git add .
   git commit -m "feat: initial CI/CD setup"
   git push origin main
   ```

4. **Customer Portal**:
   ```bash
   cd pet-customer-portal
   git add .
   git commit -m "feat: initial CI/CD setup"
   git push origin main
   ```

5. **Shared Package**:
   ```bash
   cd pet-shared
   git add .
   git commit -m "feat: initial CI/CD setup"
   git push origin main
   ```

### Verify Workflows

Check GitHub Actions tabs for each repository:
- ✅ All tests passing
- ✅ Security scans clean
- ✅ Builds successful
- ✅ Deployments working

## 🎯 Step 6: Production Deployment

### Release Process

1. **Create Release Tags**:
   ```bash
   # Backend
   cd pet-backend
   git tag v1.0.0
   git push origin v1.0.0
   
   # Frontend
   cd pet-frontend
   git tag v1.0.0
   git push origin v1.0.0
   
   # And so on for each repository...
   ```

2. **Monitor Deployments**:
   - Check GitHub Actions for deployment status
   - Verify applications are accessible
   - Run post-deployment health checks

### Health Checks

After deployment, verify:

```bash
# Backend API
curl https://api.petcare.com/health

# Frontend
curl https://app.petcare.com

# Customer Portal  
curl https://customer.petcare.com

# Mobile apps
# Check app stores for availability
```

## 📊 Step 7: Monitoring & Maintenance

### Setup Monitoring

1. **Application Performance Monitoring (APM)**:
   - Integrate Sentry for error tracking
   - Setup Lighthouse CI for performance monitoring
   - Configure uptime monitoring

2. **Log Aggregation**:
   - Centralized logging with ELK stack or similar
   - Application and infrastructure logs
   - Security event monitoring

3. **Alerting**:
   - Slack notifications for deployments
   - Email alerts for critical issues
   - PagerDuty for production incidents

### Maintenance Tasks

1. **Weekly**:
   - Review dependency update PRs
   - Check security scan results
   - Monitor performance metrics

2. **Monthly**:
   - Rotate secrets and tokens
   - Review and update documentation
   - Performance optimization review

3. **Quarterly**:
   - Security audit
   - Disaster recovery testing
   - Capacity planning review

## 🔧 Troubleshooting

### Common Issues

1. **Build Failures**:
   ```bash
   # Check Node.js versions
   # Verify dependency compatibility
   # Review error logs in GitHub Actions
   ```

2. **Deployment Issues**:
   ```bash
   # Verify secrets configuration
   # Check environment variables
   # Validate service connectivity
   ```

3. **Mobile Build Issues**:
   ```bash
   # Check signing certificate validity
   # Verify Xcode/Android SDK versions
   # Review platform-specific configurations
   ```

### Support Resources

- **GitHub Actions Logs**: Detailed build and deployment logs
- **Repository Documentation**: Each repo has specific setup instructions
- **Slack Notifications**: Real-time deployment status
- **Health Checks**: Automated endpoint monitoring

## 📚 Additional Resources

### Documentation
- [Backend API Documentation](pet-backend/API_DOCUMENTATION.md)
- [Frontend Setup Guide](pet-frontend/README.md)
- [Mobile Development Guide](pet-mobile/README.md)
- [Customer Portal Guide](pet-customer-portal/README.md)
- [Shared Package Usage](pet-shared/README.md)

### Best Practices
- Follow semantic versioning for releases
- Use feature branches for development
- Implement proper code review process
- Maintain comprehensive test coverage
- Keep dependencies up to date
- Monitor security vulnerabilities
- Document architecture decisions

This deployment setup provides a robust, scalable, and secure foundation for the Pet Care Management System with automated CI/CD pipelines that support rapid development and reliable deployments.