# 🐾 宠物管理系统 Docker 部署指南

## 🚀 快速开始

### 前提条件

- ✅ Docker Desktop 已安装并运行
- ✅ Docker Compose 可用
- ✅ 至少 4GB RAM 空闲内存
- ✅ 至少 2GB 磁盘空间

### 一键启动

```bash
# 启动简化版（推荐）
./docker-start.sh simple

# 启动完整版（包含数据库）
./docker-start.sh full

# 查看服务状态
./docker-start.sh --status

# 停止所有服务
./docker-start.sh --stop
```

## 📋 部署模式说明

### 1. 简化版模式 (simple)

**特点**：
- ✅ 快速启动，无需数据库
- ✅ 内存存储，重启后数据重置
- ✅ 适合演示和测试

**包含服务**：
- 前端 (React + Vite) - http://localhost:3001
- 后端 (Node.js 简化版) - http://localhost:8000

**启动命令**：
```bash
./docker-start.sh simple
```

### 2. 完整版模式 (full)

**特点**：
- 🔥 生产就绪的完整功能
- 💾 PostgreSQL 持久化存储
- ⚡ Redis 缓存支持
- 🔐 完整的认证和授权系统

**包含服务**：
- 前端 (React + Vite) - http://localhost:3001
- 后端 (Express + Node.js) - http://localhost:3000
- PostgreSQL 数据库 - localhost:5432
- Redis 缓存 - localhost:6379
- 客户门户 (Next.js) - http://localhost:3002

**启动命令**：
```bash
./docker-start.sh full
```

## 🔧 自定义配置

### 环境变量文件

- `.env.simple` - 简化版配置
- `.env.docker` - 完整版配置

### 端口配置

可以通过修改 docker-compose 文件来更改端口映射：

```yaml
ports:
  - "新端口:容器端口"
```

### 数据持久化

完整版模式使用 Docker volumes 来持久化数据：
- `postgres_data` - 数据库数据
- `redis_data` - Redis 数据

## 📊 服务监控

### 健康检查

```bash
# 检查简化版后端
curl http://localhost:8000/health

# 检查完整版后端
curl http://localhost:3000/api/health

# 检查前端
curl http://localhost:3001
```

### 查看日志

```bash
# 查看所有服务日志
./docker-start.sh --logs

# 查看特定服务日志
docker-compose logs frontend
docker-compose logs backend
```

### 服务状态

```bash
# 查看服务状态
./docker-start.sh --status

# 或使用 Docker Compose
docker-compose ps
```

## 🔐 默认登录凭据

### 简化版
- **用户名**: admin
- **密码**: password

### 完整版
- **用户名**: admin
- **密码**: admin123

### 数据库连接（仅完整版）
- **主机**: localhost:5432
- **数据库**: pet_management
- **用户**: pet_admin
- **密码**: pet_secure_password

## 🛠️ 开发和调试

### 重新构建镜像

```bash
# 强制重新构建
./docker-start.sh simple --build
./docker-start.sh full --build

# 或使用 Docker Compose
docker-compose build --no-cache
```

### 进入容器

```bash
# 进入后端容器
docker exec -it pet-backend sh
docker exec -it pet-simple-backend sh

# 进入前端容器
docker exec -it pet-frontend sh

# 进入数据库容器
docker exec -it pet-postgres psql -U pet_admin -d pet_management
```

### 查看容器资源使用

```bash
# 查看资源使用情况
docker stats

# 查看详细信息
docker system df
```

## 🧹 维护和清理

### 停止服务

```bash
# 优雅停止
./docker-start.sh --stop

# 强制停止并清理
./docker-start.sh --clean
```

### 清理未使用的资源

```bash
# 清理未使用的镜像、容器、网络
docker system prune -a

# 清理数据卷（注意：会删除所有数据）
docker volume prune
```

### 备份数据

```bash
# 备份数据库（仅完整版）
docker exec pet-postgres pg_dump -U pet_admin pet_management > backup.sql

# 恢复数据库
docker exec -i pet-postgres psql -U pet_admin pet_management < backup.sql
```

## 📱 API 测试

### 基本 API 调用

```bash
# 健康检查
curl http://localhost:8000/health  # 简化版
curl http://localhost:3000/api/health  # 完整版

# 获取宠物列表
curl http://localhost:8000/api/pets

# 用户登录
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

### 使用内置 API 测试页面

访问 http://localhost:3001 并打开浏览器开发者工具查看网络请求。

## 🚨 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口占用
   lsof -ti:3001,8000,3000,5432
   
   # 停止占用端口的进程
   kill $(lsof -ti:端口号)
   ```

2. **内存不足**
   ```bash
   # 增加 Docker Desktop 内存限制
   # 在 Docker Desktop > Settings > Resources > Advanced 中调整
   ```

3. **权限问题**
   ```bash
   # 确保脚本可执行
   chmod +x docker-start.sh
   ```

4. **构建失败**
   ```bash
   # 清理并重新构建
   ./docker-start.sh --clean
   ./docker-start.sh simple --build
   ```

### 获取帮助

```bash
# 查看所有可用命令
./docker-start.sh --help

# 查看详细版本信息
docker --version
docker-compose --version
```

## 🎯 生产部署建议

### 安全配置

1. 修改默认密码
2. 使用 HTTPS
3. 配置防火墙
4. 定期更新镜像

### 性能优化

1. 使用生产级数据库
2. 配置负载均衡
3. 启用缓存
4. 监控系统资源

### 备份策略

1. 定期备份数据库
2. 备份配置文件
3. 测试恢复流程

---

## 📞 技术支持

如遇到问题，请检查：
1. Docker 服务是否运行
2. 端口是否被占用
3. 系统资源是否充足
4. 网络连接是否正常

**部署状态**: 🟢 就绪  
**最后更新**: 2025-08-29  
**维护团队**: Pet Management System Team