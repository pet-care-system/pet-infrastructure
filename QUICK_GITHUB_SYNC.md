# 🚀 GitHub同步快速指南

## ⚡ 一键同步到GitHub

### 步骤 0: 配置SSH密钥 (首次使用)

```bash
# 生成SSH密钥 (如果还没有)
ssh-keygen -t ed25519 -C "your_email@example.com"

# 启动SSH agent并添加密钥
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 复制公钥 (macOS)
pbcopy < ~/.ssh/id_ed25519.pub
```

然后将公钥添加到GitHub:
1. 访问 https://github.com/settings/ssh/new
2. 粘贴公钥内容
3. 测试连接: `ssh -T git@github.com`

📖 详细SSH配置请参考: [SSH_SETUP_GUIDE.md](SSH_SETUP_GUIDE.md)

### 步骤 1: 推送代码到GitHub

```bash
cd /Users/newdroid/Documents/project

# 执行自动推送脚本 (现在使用SSH)
./github-setup.sh
```

脚本会自动：
- ✅ 创建5个GitHub仓库 (如果使用GitHub CLI)
- ✅ 配置Git远程连接
- ✅ 推送所有代码到GitHub
- ✅ 生成详细的提交信息

### 步骤 2: 配置GitHub Secrets

```bash
# 配置所有必要的Secrets
./setup-secrets.sh
```

脚本会引导你配置：
- 🔐 JWT认证密钥
- 🗄️ 数据库连接信息  
- 🐳 Docker Hub配置
- ⚡ 部署服务配置

### 步骤 3: 验证部署

访问你的GitHub仓库，检查：
- ✅ 代码推送成功
- ✅ GitHub Actions运行正常
- ✅ Secrets配置完整

## 📋 手动操作指南 (备选方案)

如果脚本无法使用，可以手动操作：

### 1. 创建GitHub仓库

在GitHub上创建以下5个私有仓库：
- `pet-backend`
- `pet-frontend` 
- `pet-mobile`
- `pet-customer-portal`
- `pet-shared`

### 2. 手动推送代码

```bash
# 对每个仓库执行以下操作 (使用SSH)
cd /Users/newdroid/Documents/project/pet-backend

git init
git branch -M main
git add .
git commit -m "🎉 初始提交"
git remote add origin git@github.com:你的用户名/pet-backend.git
git push -u origin main
```

### 3. 手动配置Secrets

访问每个仓库的 `Settings` → `Secrets and variables` → `Actions`，添加：

**通用Secrets (所有仓库):**
- `JWT_SECRET`: JWT签名密钥
- `JWT_REFRESH_SECRET`: 刷新令牌密钥  
- `DB_PASSWORD`: 数据库密码
- `REDIS_PASSWORD`: Redis密码

**仓库特定Secrets:**
- `pet-backend`: `DOCKER_USERNAME`, `DOCKER_PASSWORD`
- `pet-frontend`: `VITE_API_BASE_URL`, `VERCEL_TOKEN`
- `pet-shared`: `NPM_TOKEN`

## 🔍 验证清单

完成后检查以下项目：

### GitHub仓库状态
- [ ] 5个仓库创建成功
- [ ] 代码完整推送
- [ ] README.md显示正常
- [ ] GitHub Actions配置存在

### CI/CD流水线  
- [ ] GitHub Actions运行成功
- [ ] 代码检查通过
- [ ] 测试执行成功
- [ ] Docker构建成功

### 配置完整性
- [ ] 所有Secrets配置完成
- [ ] 环境变量设置正确
- [ ] 仓库权限配置合适

## 🌐 访问链接

推送完成后，你的仓库将在：
- 🔙 后端: `https://github.com/你的用户名/pet-backend`
- 🖥️ 前端: `https://github.com/你的用户名/pet-frontend`
- 📱 移动端: `https://github.com/你的用户名/pet-mobile`
- 👥 客户门户: `https://github.com/你的用户名/pet-customer-portal`
- 📦 共享包: `https://github.com/你的用户名/pet-shared`

**克隆方式 (SSH)**:
```bash
git clone git@github.com:你的用户名/pet-backend.git
```

## 🆘 常见问题

### Q: SSH连接失败？
```bash
# 测试SSH连接
ssh -T git@github.com

# 如果失败，请检查SSH配置
# 详见 SSH_SETUP_GUIDE.md
```

### Q: 推送被拒绝？
```bash
# 强制推送 (仅限初次设置)
git push -f origin main
```

### Q: GitHub CLI未安装？
```bash
# macOS
brew install gh

# Windows  
winget install GitHub.CLI

# 登录
gh auth login
```

### Q: Secrets配置失败？
- 检查仓库权限
- 确认GitHub CLI已登录
- 手动在网页界面配置

### Q: CI/CD失败？
- 检查Secrets是否正确配置
- 查看GitHub Actions日志
- 确认依赖项正确安装

## 🎉 完成！

同步完成后，你的宠物管理系统将：
- ✅ 在GitHub上有完整的代码备份
- ✅ 拥有自动化的CI/CD流水线  
- ✅ 支持多环境部署
- ✅ 具备完整的版本控制

**下一步**: 开始基于微服务架构进行开发！🚀

---
📖 详细文档: [GITHUB_SETUP_GUIDE.md](GITHUB_SETUP_GUIDE.md)
🏗️ 项目总结: [MONOREPO_SEPARATION_SUMMARY.md](MONOREPO_SEPARATION_SUMMARY.md)