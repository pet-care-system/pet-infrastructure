# 🚨 Docker 部署故障排除指南

## 网络连接问题

### 问题症状
```
failed to fetch oauth token: Post "https://auth.docker.io/token": dial tcp 31.13.112.9:443: i/o timeout
```

### 解决方案

#### 方案 1: 等待网络恢复
Docker Hub 可能暂时不可用，请等待几分钟后重试。

#### 方案 2: 使用代理或镜像源
```bash
# 配置 Docker 使用国内镜像
# 在 ~/.docker/daemon.json 中添加：
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ]
}
```

#### 方案 3: 使用本地 Node.js 运行（推荐）

由于我们已经成功在本地运行过项目，可以直接使用本地环境：

```bash
# 启动简化版后端
node simple-backend.js &

# 启动前端（在另一个终端）
cd pet-frontend && npm run preview
```

## 🔧 本地运行完整指南

### 1. 准备工作

确保以下依赖已安装：
```bash
# 检查 Node.js 版本
node --version  # 需要 >= 18

# 检查 npm 版本
npm --version
```

### 2. 启动简化版系统

```bash
# 项目根目录
cd /Users/newdroid/Documents/project

# 启动简化版后端（端口 8000）
node simple-backend.js &

# 进入前端目录并启动
cd pet-frontend
npm run preview  # 端口 3001
```

### 3. 启动完整版系统

```bash
# 启动 PostgreSQL（需要先安装）
# macOS: brew install postgresql
# brew services start postgresql

# 创建数据库
createdb pet_management

# 启动完整版后端
cd pet-backend
npm install
npm start  # 端口 3000

# 启动前端
cd ../pet-frontend
npm install
npm run preview  # 端口 3001
```

### 4. 验证服务

```bash
# 检查简化版后端
curl http://localhost:8000/health

# 检查完整版后端
curl http://localhost:3000/api/health

# 检查前端
curl http://localhost:3001
```

## ⚡ 快速启动脚本

创建 `local-start.sh` 脚本：

```bash
#!/bin/bash

echo "🐾 启动宠物管理系统（本地版本）"

# 启动简化版后端
echo "启动后端服务..."
node simple-backend.js &
BACKEND_PID=$!

# 等待后端启动
sleep 2

# 启动前端
echo "启动前端服务..."
cd pet-frontend
npm run preview &
FRONTEND_PID=$!

echo ""
echo "🎉 系统启动成功！"
echo "📱 前端: http://localhost:3001"
echo "🔌 后端: http://localhost:8000"
echo ""
echo "🔑 登录凭据:"
echo "   用户名: admin"
echo "   密码:   password"
echo ""
echo "按 Ctrl+C 停止服务"

# 等待用户中断
trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait
```

使脚本可执行并运行：
```bash
chmod +x local-start.sh
./local-start.sh
```

## 🐳 Docker 镜像预拉取

当网络恢复后，可以预先拉取所需镜像：

```bash
# 拉取 Node.js 镜像
docker pull node:18-alpine

# 拉取 nginx 镜像
docker pull nginx:alpine

# 拉取 PostgreSQL 镜像
docker pull postgres:15-alpine

# 拉取 Redis 镜像
docker pull redis:7-alpine

# 验证镜像
docker images
```

## 🔍 常见问题诊断

### 1. 端口占用

```bash
# 查看端口占用
lsof -ti:3001,8000,3000

# 终止占用进程
kill $(lsof -ti:端口号)
```

### 2. Node.js 版本问题

```bash
# 使用 nvm 管理 Node.js 版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

### 3. 依赖安装失败

```bash
# 清理 npm 缓存
npm cache clean --force

# 删除 node_modules 重新安装
rm -rf node_modules package-lock.json
npm install
```

### 4. 数据库连接问题

```bash
# 检查 PostgreSQL 状态
pg_isready

# 启动 PostgreSQL
brew services start postgresql  # macOS
sudo systemctl start postgresql  # Linux
```

## 📋 系统要求

### 最低配置
- **CPU**: 2核心
- **内存**: 4GB RAM
- **存储**: 2GB 可用空间
- **Node.js**: >= 18.0.0
- **npm**: >= 8.0.0

### 推荐配置
- **CPU**: 4核心
- **内存**: 8GB RAM
- **存储**: 5GB 可用空间
- **SSD**: 固态硬盘

## 🆘 获取帮助

### 日志收集

```bash
# 收集系统信息
docker --version > debug-info.txt
node --version >> debug-info.txt
npm --version >> debug-info.txt
uname -a >> debug-info.txt

# 收集错误日志
docker-compose logs > docker-logs.txt 2>&1
```

### 重置环境

```bash
# 清理 Docker 环境
docker system prune -a -f

# 清理项目依赖
cd pet-frontend && rm -rf node_modules package-lock.json
cd ../pet-backend && rm -rf node_modules package-lock.json

# 重新安装
npm install
```

---

**状态**: 🟡 网络问题解决方案  
**更新**: 2025-08-29  
**维护**: Pet Management System Team