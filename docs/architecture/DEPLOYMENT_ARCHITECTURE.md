# 宠物管理系统分离后部署架构

## 🏗️ 总体架构

```
                    ┌─────────────────────────────────────┐
                    │         负载均衡器/API Gateway        │
                    │      (Nginx/Traefik/AWS ALB)        │
                    └─────────────────┬───────────────────┘
                                     │
                    ┌─────────────────┼───────────────────┐
                    │                 │                   │
           ┌────────▼────────┐ ┌─────▼─────┐ ┌─────────▼──────┐
           │  Web Frontend   │ │  Mobile   │ │ Customer Portal │
           │    (3001)       │ │ Backend   │ │     (3002)      │
           │                 │ │  (3001)   │ │                 │
           └─────────────────┘ └───────────┘ └─────────────────┘
                    │                 │                   │
                    └─────────────────┼───────────────────┘
                                     │
                    ┌─────────────────▼───────────────────┐
                    │          Backend API                 │
                    │           (3000)                     │
                    │    (共享认证 + 核心业务)              │
                    └─────────────────────────────────────┘
                                     │
                ┌────────────────────┼────────────────────┐
                │                    │                    │
      ┌─────────▼──────┐   ┌────────▼────────┐   ┌─────▼─────┐
      │   PostgreSQL    │   │     Redis       │   │   Nginx   │
      │   (Database)    │   │    (Cache)      │   │(Static)   │
      └─────────────────┘   └─────────────────┘   └───────────┘
```

## 📦 服务部署清单

### 1. **pet-backend** - 核心API服务
- **端口**: 3000
- **数据库**: PostgreSQL + Redis
- **功能**: 用户认证、宠物管理、喂食记录、报表生成
- **部署方式**: Docker容器 + PM2
- **扩展策略**: 水平扩展 + 负载均衡

### 2. **pet-frontend** - Web前端
- **端口**: 3001 (开发) / 80 (生产)
- **构建**: Vite + React
- **部署方式**: Nginx静态文件服务
- **CDN**: 静态资源CDN加速
- **扩展策略**: 多区域部署

### 3. **pet-mobile** - 移动端应用
- **后端端口**: 3001 (与mobile-backend整合)
- **功能**: IoT设备通信、离线同步、推送通知
- **部署方式**: Docker容器
- **特殊配置**: MQTT Broker集成

### 4. **pet-customer-portal** - 客户门户
- **端口**: 3002
- **框架**: Next.js
- **部署方式**: Vercel/PM2 + Nginx
- **特点**: SSR/SSG优化

### 5. **pet-shared** - 共享包
- **类型**: npm包
- **发布**: npm registry
- **版本管理**: 语义化版本控制

## 🐳 Docker Compose 统一配置

创建根目录的统一部署配置：

```yaml
# /Users/newdroid/Documents/project/docker-compose.production.yml
version: '3.8'

services:
  # 数据库服务
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: pet_system
      POSTGRES_USER: ${DB_USER:-petuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-petpass123}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - pet-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-petuser}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis缓存
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-redispass123}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - pet-network

  # 后端API服务
  backend:
    build:
      context: ./pet-backend
      dockerfile: Dockerfile
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      REDIS_HOST: redis
      JWT_SECRET: ${JWT_SECRET}
      PORT: 3000
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - pet-network
    volumes:
      - backend_logs:/app/logs

  # Web前端
  frontend:
    build:
      context: ./pet-frontend
      dockerfile: Dockerfile
    environment:
      VITE_API_BASE_URL: ${VITE_API_BASE_URL:-http://backend:3000/api}
    ports:
      - "3001:80"
    depends_on:
      - backend
    networks:
      - pet-network

  # 移动端后端
  mobile-backend:
    build:
      context: ./pet-mobile
      dockerfile: Dockerfile.backend
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      REDIS_HOST: redis
      MQTT_BROKER_URL: ${MQTT_BROKER_URL}
    ports:
      - "3003:3003"
    depends_on:
      - postgres
      - redis
    networks:
      - pet-network

  # 客户门户
  customer-portal:
    build:
      context: ./pet-customer-portal
      dockerfile: Dockerfile
    environment:
      NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL:-http://backend:3000/api}
    ports:
      - "3002:3000"
    depends_on:
      - backend
    networks:
      - pet-network

  # Nginx负载均衡
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
      - customer-portal
    networks:
      - pet-network

volumes:
  postgres_data:
  redis_data:
  backend_logs:

networks:
  pet-network:
    driver: bridge
```

## 🎯 Nginx负载均衡配置

```nginx
# /Users/newdroid/Documents/project/nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream backend_servers {
        server backend:3000;
        # 可以添加更多backend实例
        # server backend-2:3000;
    }

    upstream frontend_servers {
        server frontend:80;
    }

    upstream portal_servers {
        server customer-portal:3000;
    }

    # Web前端
    server {
        listen 80;
        server_name app.petcare.com;

        location / {
            proxy_pass http://frontend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # API代理
        location /api/ {
            proxy_pass http://backend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # 客户门户
    server {
        listen 80;
        server_name customer.petcare.com;

        location / {
            proxy_pass http://portal_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # 移动端API
    server {
        listen 80;
        server_name mobile-api.petcare.com;

        location / {
            proxy_pass http://mobile-backend:3003;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket支持
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
```

## 🚀 部署脚本

```bash
#!/bin/bash
# /Users/newdroid/Documents/project/deploy-all.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 开始部署宠物管理系统...${NC}"

# 检查环境
check_environment() {
    echo -e "${YELLOW}🔍 检查部署环境...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 环境检查通过${NC}"
}

# 构建所有服务
build_services() {
    echo -e "${YELLOW}🔧 构建所有服务...${NC}"
    
    # 构建共享包
    echo "构建 pet-shared 包..."
    cd pet-shared && npm run build && cd ..
    
    # 构建各个服务
    docker-compose -f docker-compose.production.yml build --no-cache
    
    echo -e "${GREEN}✅ 所有服务构建完成${NC}"
}

# 启动服务
start_services() {
    echo -e "${YELLOW}🎬 启动所有服务...${NC}"
    
    docker-compose -f docker-compose.production.yml up -d
    
    echo -e "${GREEN}✅ 所有服务启动完成${NC}"
}

# 健康检查
health_check() {
    echo -e "${YELLOW}🏥 执行健康检查...${NC}"
    
    services=("postgres" "redis" "backend" "frontend" "customer-portal" "nginx")
    
    for service in "${services[@]}"; do
        echo "检查 $service..."
        
        max_attempts=30
        attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if docker-compose -f docker-compose.production.yml ps $service | grep "Up (healthy\|Up)" > /dev/null; then
                echo -e "${GREEN}✅ $service 运行正常${NC}"
                break
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                echo -e "${RED}❌ $service 健康检查失败${NC}"
                docker-compose -f docker-compose.production.yml logs $service
                exit 1
            fi
            
            sleep 5
            ((attempt++))
        done
    done
    
    echo -e "${GREEN}✅ 所有服务健康检查通过${NC}"
}

# 显示服务状态
show_status() {
    echo -e "${YELLOW}📊 服务状态总览:${NC}"
    docker-compose -f docker-compose.production.yml ps
    
    echo -e "\n${GREEN}🌐 访问地址:${NC}"
    echo "Web前端: http://localhost:3001"
    echo "客户门户: http://localhost:3002"
    echo "后端API: http://localhost:3000"
    echo "Nginx网关: http://localhost"
}

# 主函数
main() {
    check_environment
    build_services
    start_services
    health_check
    show_status
    
    echo -e "\n${GREEN}🎉 部署完成! 所有服务运行正常${NC}"
}

# 处理参数
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "stop")
        echo -e "${YELLOW}🛑 停止所有服务...${NC}"
        docker-compose -f docker-compose.production.yml down
        ;;
    "restart")
        echo -e "${YELLOW}🔄 重启所有服务...${NC}"
        docker-compose -f docker-compose.production.yml restart
        ;;
    "logs")
        docker-compose -f docker-compose.production.yml logs -f "${2:-}"
        ;;
    "status")
        show_status
        ;;
    *)
        echo "使用方法: $0 {deploy|stop|restart|logs [service]|status}"
        exit 1
        ;;
esac
```

## 📊 监控和日志配置

### Prometheus监控配置

```yaml
# /Users/newdroid/Documents/project/monitoring/docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - pet-network

  grafana:
    image: grafana/grafana
    ports:
      - "3004:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - pet-network

volumes:
  grafana_data:

networks:
  pet-network:
    external: true
```

### ELK日志栈配置

```yaml
# /Users/newdroid/Documents/project/logging/docker-compose.logging.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  kibana:
    image: docker.elastic.co/kibana/kibana:8.5.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    depends_on:
      - elasticsearch

  logstash:
    image: docker.elastic.co/logstash/logstash:8.5.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch

volumes:
  elasticsearch_data:
```

## 🔐 环境变量配置

```bash
# /Users/newdroid/Documents/project/.env.production
# 数据库配置
DB_USER=petuser
DB_PASSWORD=your-strong-db-password
DB_NAME=pet_system

# Redis配置
REDIS_PASSWORD=your-redis-password

# JWT配置
JWT_SECRET=your-super-secret-jwt-key-256-bit
JWT_REFRESH_SECRET=your-refresh-token-secret

# API配置
VITE_API_BASE_URL=https://api.petcare.com/api
NEXT_PUBLIC_API_URL=https://api.petcare.com/api

# 第三方服务
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-secret
GOOGLE_CLIENT_ID=your-google-client-id

# 邮件服务
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# 对象存储
AWS_S3_BUCKET=pet-care-uploads
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# 监控配置
SENTRY_DSN=your-sentry-dsn
```

## 🔧 维护和运维

### 备份策略

```bash
#!/bin/bash
# /Users/newdroid/Documents/project/scripts/backup.sh

# 数据库备份
docker exec postgres pg_dump -U petuser pet_system > "backup_$(date +%Y%m%d_%H%M%S).sql"

# Redis备份
docker exec redis redis-cli SAVE
docker cp redis:/data/dump.rdb "redis_backup_$(date +%Y%m%d_%H%M%S).rdb"

# 上传到云存储
aws s3 cp backup_*.sql s3://pet-care-backups/database/
aws s3 cp redis_backup_*.rdb s3://pet-care-backups/redis/
```

### 自动扩展策略

- **水平扩展**: 基于CPU/内存使用率自动增加容器实例
- **数据库连接池**: 动态调整连接池大小
- **缓存策略**: Redis集群模式支持
- **CDN加速**: 静态资源全球分发

### 灾难恢复

- **定期备份**: 每日自动数据库备份
- **多区域部署**: 主备数据中心
- **快速恢复**: RTO < 30分钟，RPO < 1小时
- **监控告警**: 24/7监控和自动故障转移

这个部署架构支持：
- 🚀 **高可用性**: 多实例部署和负载均衡
- 📈 **可扩展性**: 水平和垂直扩展支持
- 🔒 **安全性**: SSL/TLS加密、防火墙、权限控制
- 📊 **可观测性**: 完整的监控、日志和告警
- 🔄 **CI/CD**: 自动化部署和版本管理