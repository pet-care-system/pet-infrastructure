# 🐳 手动Docker部署指南

## 当前网络问题

由于Docker Hub网络连接问题，自动Docker部署暂时无法使用。以下提供几种解决方案：

## 🎯 推荐方案：继续使用本地部署

**最简单和稳定的方式**：

```bash
# 启动本地版本（已验证可用）
./local-start.sh simple

# 访问系统
前端: http://localhost:3001
后端: http://localhost:8000
登录: admin / password
```

## 🔧 方案1: 手动下载Docker镜像

### 1. 下载必需的镜像

```bash
# 方法A: 使用镜像加速器
export DOCKER_REGISTRY_MIRROR="https://docker.mirrors.ustc.edu.cn"

# 方法B: 手动下载核心镜像
docker pull node:18-alpine
docker pull nginx:alpine
docker pull postgres:15-alpine
docker pull redis:7-alpine
```

### 2. 验证镜像下载

```bash
docker images
```

### 3. 启动Docker服务

```bash
# 简化版
./docker-start.sh simple

# 完整版
./docker-start.sh full
```

## 🛠️ 方案2: 使用本地镜像构建

### 1. 创建本地Dockerfile

我们已经创建了无网络依赖的配置文件：
- `Dockerfile.local-backend` - 本地后端镜像
- `docker-compose.local.yml` - 本地编排配置

### 2. 使用本地配置启动

```bash
# 使用本地配置
docker-compose -f docker-compose.local.yml up --build
```

## 📊 方案3: 混合部署

### 后端使用Docker，前端使用本地

```bash
# 1. 启动Docker化的后端
docker run -d --name pet-backend \
  -p 8000:8000 \
  -v $(pwd):/app \
  -w /app \
  node:18-alpine \
  node simple-backend.js

# 2. 启动本地前端
cd pet-frontend && npm run preview
```

## 🌐 方案4: 完全容器化（网络恢复后）

### 完整的Docker Compose配置

```yaml
# docker-compose.yml (已存在)
version: '3.8'

services:
  postgres:      # PostgreSQL数据库
    image: postgres:15-alpine
    ports: ["5432:5432"]
    
  redis:         # Redis缓存
    image: redis:7-alpine
    ports: ["6379:6379"]
    
  backend:       # 完整版后端
    build: ./pet-backend
    ports: ["3000:3000"]
    depends_on: [postgres, redis]
    
  frontend:      # React前端
    build: ./pet-frontend
    ports: ["3001:80"]
    depends_on: [backend]
```

## 🔍 故障排除

### 网络问题诊断

```bash
# 测试Docker Hub连接
curl -I https://registry-1.docker.io/

# 测试镜像拉取
docker pull hello-world

# 检查Docker状态
docker system info
```

### 使用国内镜像源

```bash
# 配置Docker镜像加速器
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ]
}
EOF

# 重启Docker服务
sudo systemctl restart docker  # Linux
# 或在Docker Desktop中重启
```

## ✅ 验证部署

### 健康检查命令

```bash
# 检查容器状态
docker ps

# 检查服务健康
curl http://localhost:8000/health
curl http://localhost:3001

# 检查日志
docker logs pet-simple-backend
docker logs pet-frontend
```

## 📋 当前建议

**由于网络问题，推荐使用本地部署**：

1. **继续使用本地版本** - 已验证稳定可用
2. **等待网络改善** - 之后使用Docker部署
3. **使用混合方案** - 部分服务Docker化

### 快速启动本地版本

```bash
# 一键启动（推荐）
./local-start.sh simple

# 访问系统
浏览器打开: http://localhost:3001
登录凭据: admin / password
```

---

**状态**: 🟡 网络限制，本地部署可用  
**更新**: 2025-08-29  
**维护**: Pet Management System Team