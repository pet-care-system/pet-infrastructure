# 🚀 GitHub仓库设置指南

## 📋 概览

将分离后的5个独立仓库同步到GitHub，并配置完整的CI/CD流水线。

### 仓库清单
- `pet-backend` - 核心后端API服务
- `pet-frontend` - Web前端应用
- `pet-mobile` - 移动端应用
- `pet-customer-portal` - 客户门户
- `pet-shared` - 共享npm包

## 🛠️ 操作步骤

### 步骤1: 在GitHub上创建仓库

#### 方法A: 通过GitHub网页界面创建

1. 访问 [GitHub](https://github.com)
2. 点击右上角 "+" -> "New repository"
3. 创建以下5个仓库：

| 仓库名 | 描述 | 可见性 |
|--------|------|-------|
| `pet-backend` | 宠物管理系统后端API服务 | Private |
| `pet-frontend` | 宠物管理系统Web前端 | Private |
| `pet-mobile` | 宠物管理系统移动端应用 | Private |
| `pet-customer-portal` | 宠物管理系统客户门户 | Private |
| `pet-shared` | 宠物管理系统共享组件库 | Private |

**注意**: 
- ✅ 不要初始化README.md (本地已有)
- ✅ 不要添加.gitignore (本地已配置)
- ✅ 选择Private确保代码安全

#### 方法B: 使用GitHub CLI创建 (推荐)

```bash
# 安装GitHub CLI (如果未安装)
# macOS: brew install gh
# Windows: winget install GitHub.CLI

# 登录GitHub
gh auth login

# 批量创建仓库
gh repo create pet-backend --private --description "宠物管理系统后端API服务"
gh repo create pet-frontend --private --description "宠物管理系统Web前端"
gh repo create pet-mobile --private --description "宠物管理系统移动端应用"
gh repo create pet-customer-portal --private --description "宠物管理系统客户门户"
gh repo create pet-shared --private --description "宠物管理系统共享组件库"
```

### 步骤2: 配置本地Git并推送代码

创建自动化推送脚本：

```bash
#!/bin/bash
# /Users/newdroid/Documents/project/github-setup.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# GitHub用户名 (请替换为你的用户名)
GITHUB_USERNAME="your-github-username"

echo -e "${GREEN}🚀 开始设置GitHub仓库...${NC}"

# 仓库配置
repos=(
    "pet-backend:宠物管理系统后端API服务"
    "pet-frontend:宠物管理系统Web前端"
    "pet-mobile:宠物管理系统移动端应用"
    "pet-customer-portal:宠物管理系统客户门户"
    "pet-shared:宠物管理系统共享组件库"
)

# 推送单个仓库的函数
push_repo() {
    local repo_name=$1
    local description=$2
    local repo_path="/Users/newdroid/Documents/project/${repo_name}"
    
    echo -e "${YELLOW}📦 处理仓库: ${repo_name}${NC}"
    
    if [ ! -d "$repo_path" ]; then
        echo -e "${RED}❌ 目录不存在: $repo_path${NC}"
        return 1
    fi
    
    cd "$repo_path"
    
    # 检查是否已经是git仓库
    if [ ! -d ".git" ]; then
        echo "初始化Git仓库..."
        git init
        git branch -M main
    fi
    
    # 添加远程仓库
    if git remote get-url origin >/dev/null 2>&1; then
        echo "更新远程仓库URL..."
        git remote set-url origin "https://github.com/${GITHUB_USERNAME}/${repo_name}.git"
    else
        echo "添加远程仓库..."
        git remote add origin "https://github.com/${GITHUB_USERNAME}/${repo_name}.git"
    fi
    
    # 添加所有文件
    git add .
    
    # 提交代码 (如果有更改)
    if git diff --staged --quiet; then
        echo "没有新的更改需要提交"
    else
        echo "提交代码..."
        git commit -m "🎉 初始提交: ${description}

✨ 功能特性:
- 完整的项目结构和代码
- TypeScript支持和类型定义
- Docker容器化配置
- GitHub Actions CI/CD流水线
- 完善的文档和使用指南

🔧 技术栈:
$(if [ -f "package.json" ]; then
    echo "- Node.js + $(grep -o '"[^"]*":\s*"[^"]*"' package.json | head -3 | sed 's/"//g' | sed 's/:/:/g')"
else
    echo "- 详见项目README.md"
fi)

📝 使用说明:
请查看README.md了解详细的安装和使用说明

🤖 自动化部署:
- GitHub Actions CI/CD已配置
- 支持多环境部署 (dev/staging/prod)
- 自动化测试和质量检查

Generated with Claude Code"
    fi
    
    # 推送到远程仓库
    echo "推送到GitHub..."
    if git push -u origin main 2>/dev/null; then
        echo -e "${GREEN}✅ ${repo_name} 推送成功${NC}"
    else
        echo "首次推送，尝试强制推送..."
        git push -f -u origin main
        echo -e "${GREEN}✅ ${repo_name} 强制推送成功${NC}"
    fi
    
    echo "🌐 仓库地址: https://github.com/${GITHUB_USERNAME}/${repo_name}"
    echo ""
}

# 检查GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI未安装，请手动在GitHub网页创建仓库${NC}"
    echo "或者运行: brew install gh (macOS) 或 winget install GitHub.CLI (Windows)"
else
    # 检查是否已登录
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  请先登录GitHub CLI: gh auth login${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI已就绪${NC}"
fi

# 批量处理所有仓库
for repo_config in "${repos[@]}"; do
    IFS=':' read -r repo_name description <<< "$repo_config"
    push_repo "$repo_name" "$description"
done

echo -e "${GREEN}🎉 所有仓库设置完成！${NC}"
echo ""
echo -e "${YELLOW}📋 下一步操作：${NC}"
echo "1. 配置GitHub Secrets (见下方说明)"
echo "2. 验证CI/CD流水线运行"
echo "3. 设置仓库保护规则"
echo ""
echo -e "${YELLOW}🔗 仓库链接：${NC}"
for repo_config in "${repos[@]}"; do
    IFS=':' read -r repo_name description <<< "$repo_config"
    echo "- https://github.com/${GITHUB_USERNAME}/${repo_name}"
done
```

执行推送脚本：

```bash
# 给脚本执行权限
chmod +x /Users/newdroid/Documents/project/github-setup.sh

# 修改脚本中的GITHUB_USERNAME为你的GitHub用户名
# 然后执行
cd /Users/newdroid/Documents/project
./github-setup.sh
```

### 步骤3: 配置GitHub Secrets

每个仓库都需要配置Secrets来支持CI/CD流水线：

#### 3.1 通用Secrets (所有仓库都需要)

| Secret名称 | 用途 | 示例值 |
|------------|------|--------|
| `JWT_SECRET` | JWT令牌签名 | `your-super-secret-jwt-key-256-bit` |
| `JWT_REFRESH_SECRET` | 刷新令牌签名 | `your-refresh-token-secret-key` |
| `DB_PASSWORD` | 数据库密码 | `your-database-password` |
| `REDIS_PASSWORD` | Redis密码 | `your-redis-password` |

#### 3.2 仓库特定Secrets

**pet-backend:**
```bash
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-password
DB_HOST=your-database-host
DB_USER=petuser
DB_NAME=pet_system
SENTRY_DSN=your-sentry-dsn-url
```

**pet-frontend:**
```bash
VITE_API_BASE_URL=https://api.petcare.com/api
VITE_AUTH_BASE_URL=https://api.petcare.com
VERCEL_TOKEN=your-vercel-token (如果使用Vercel部署)
```

**pet-mobile:**
```bash
FIREBASE_SERVICE_ACCOUNT=your-firebase-service-account-json
APPLE_CERTIFICATE=your-ios-certificate
ANDROID_KEYSTORE=your-android-keystore
EXPO_TOKEN=your-expo-token
```

**pet-customer-portal:**
```bash
NEXT_PUBLIC_API_URL=https://api.petcare.com/api
VERCEL_TOKEN=your-vercel-token
```

**pet-shared:**
```bash
NPM_TOKEN=your-npm-publish-token
```

#### 3.3 批量设置Secrets脚本

```bash
#!/bin/bash
# /Users/newdroid/Documents/project/setup-secrets.sh

GITHUB_USERNAME="your-github-username"

# 通用secrets
common_secrets=(
    "JWT_SECRET:your-super-secret-jwt-key-256-bit"
    "JWT_REFRESH_SECRET:your-refresh-token-secret-key"
    "DB_PASSWORD:your-database-password"
    "REDIS_PASSWORD:your-redis-password"
)

repos=("pet-backend" "pet-frontend" "pet-mobile" "pet-customer-portal" "pet-shared")

echo "🔐 设置GitHub Secrets..."

for repo in "${repos[@]}"; do
    echo "设置 ${repo} 的Secrets..."
    
    for secret in "${common_secrets[@]}"; do
        IFS=':' read -r name value <<< "$secret"
        echo "  设置 ${name}..."
        echo "${value}" | gh secret set "${name}" --repo "${GITHUB_USERNAME}/${repo}"
    done
done

echo "✅ 通用Secrets设置完成"
echo "⚠️  请手动设置每个仓库特定的Secrets"
```

#### 3.4 手动设置Secrets步骤

1. 访问仓库页面：`https://github.com/your-username/repo-name`
2. 点击 `Settings` -> `Secrets and variables` -> `Actions`
3. 点击 `New repository secret`
4. 输入名称和值，点击 `Add secret`

### 步骤4: 验证CI/CD流水线

推送代码后，GitHub Actions会自动运行：

```bash
# 检查workflow状态
gh run list --repo your-username/pet-backend

# 查看特定run的日志
gh run view --repo your-username/pet-backend

# 重新运行失败的workflow
gh run rerun --repo your-username/pet-backend
```

### 步骤5: 配置仓库保护规则

为了确保代码质量，建议设置分支保护规则：

```bash
# 为每个仓库设置main分支保护
repos=("pet-backend" "pet-frontend" "pet-mobile" "pet-customer-portal" "pet-shared")

for repo in "${repos[@]}"; do
    echo "设置 ${repo} 分支保护..."
    
    # 设置分支保护规则
    gh api repos/${GITHUB_USERNAME}/${repo}/branches/main/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["CI"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
        --field restrictions=null
done
```

## 📊 验证清单

完成设置后，请验证以下项目：

### ✅ GitHub仓库检查清单

- [ ] 5个仓库全部创建成功
- [ ] 代码完整推送到远程仓库
- [ ] README.md显示正常
- [ ] .github/workflows文件夹存在
- [ ] 所有必要的Secrets已配置

### ✅ CI/CD检查清单

- [ ] GitHub Actions workflow运行成功
- [ ] 代码检查(ESLint)通过
- [ ] 单元测试执行成功
- [ ] Docker镜像构建成功
- [ ] 安全扫描无高危漏洞

### ✅ 功能检查清单

**pet-backend:**
- [ ] 健康检查端点响应正常
- [ ] 数据库连接成功
- [ ] JWT认证功能正常

**pet-frontend:**
- [ ] 构建产物生成成功
- [ ] 静态资源部署正常
- [ ] API调用配置正确

**pet-mobile:**
- [ ] React Native构建成功
- [ ] Android/iOS项目配置正确
- [ ] 推送通知配置完成

**pet-customer-portal:**
- [ ] Next.js构建成功
- [ ] SSR/SSG功能正常
- [ ] 路由配置正确

**pet-shared:**
- [ ] npm包构建成功
- [ ] TypeScript类型导出正确
- [ ] 版本管理正常

## 🚨 常见问题解决

### 问题1: 推送被拒绝
```bash
# 解决方案：强制推送 (仅限初次设置)
git push -f origin main
```

### 问题2: GitHub Actions失败
```bash
# 查看详细日志
gh run view --log --repo your-username/repo-name

# 常见原因：
# 1. Secrets未配置
# 2. 依赖安装失败
# 3. 测试用例失败
```

### 问题3: Docker构建失败
```bash
# 本地测试Docker构建
docker build -t test-image .

# 检查Dockerfile语法
# 确保.dockerignore文件正确
```

### 问题4: npm包发布失败
```bash
# 检查npm token权限
npm whoami

# 检查package.json配置
# 确保版本号正确递增
```

## 📞 支持和帮助

如果遇到问题，可以：

1. **检查文档**: 查看各仓库的README.md
2. **查看日志**: 使用GitHub Actions日志排查问题
3. **社区支持**: 在GitHub Issues中报告问题
4. **技术支持**: 联系开发团队

## 🎉 完成

设置完成后，你将拥有：

- ✅ 5个独立的GitHub仓库
- ✅ 完整的CI/CD自动化流水线
- ✅ 安全的Secrets管理
- ✅ 分支保护和代码审查机制
- ✅ 自动化测试和部署

**下一步**: 开始使用新的微服务架构进行开发！🚀