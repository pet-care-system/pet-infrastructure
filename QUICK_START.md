# 🚀 宠物管理系统 - 快速开始

## ⚡ 1分钟快速启动

### 📋 前提条件
- ✅ Node.js >= 18.0 已安装
- ✅ npm 可用

### 🎯 一键启动

```bash
# 进入项目目录
cd /Users/newdroid/Documents/project

# 启动系统（推荐）
./local-start.sh simple
```

### 🌐 访问系统

- **前端界面**: http://localhost:3001
- **后端API**: http://localhost:8000
- **健康检查**: http://localhost:8000/health

### 🔑 登录信息

- **用户名**: admin
- **密码**: password

---

## 🛠️ 其他启动方式

### Docker 启动（网络良好时）

```bash
# Docker 简化版
./docker-start.sh simple

# Docker 完整版（包含数据库）
./docker-start.sh full
```

### 手动启动

```bash
# 启动后端
node simple-backend.js &

# 启动前端（新终端）
cd pet-frontend && npm run preview
```

---

## 🔧 管理命令

```bash
# 查看服务状态
./local-start.sh --status

# 停止所有服务
./local-start.sh --stop

# 重新安装依赖
./local-start.sh --install
```

---

## 📋 功能测试

### API 测试

```bash
# 获取宠物列表
curl http://localhost:8000/api/pets

# 用户登录
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

### Web 界面测试

1. 打开 http://localhost:3001
2. 使用 admin/password 登录
3. 查看宠物管理功能

---

## 🆘 遇到问题？

### 端口被占用

```bash
# 查看端口占用
lsof -ti:3001,8000

# 停止占用进程
./local-start.sh --stop
```

### Node.js 版本过低

```bash
# 安装新版本 Node.js
# 访问: https://nodejs.org/
```

### 网络问题

- 使用本地部署: `./local-start.sh simple`
- 查看故障排除: `DOCKER_TROUBLESHOOTING.md`

---

## 📖 详细文档

- 🐳 **Docker 部署**: `DOCKER_DEPLOYMENT_GUIDE.md`
- 🚨 **故障排除**: `DOCKER_TROUBLESHOOTING.md`
- 📊 **完整总结**: `DOCKER_SETUP_SUMMARY.md`

---

**状态**: 🟢 就绪使用  
**推荐**: 本地部署方式  
**维护**: Pet Management System Team