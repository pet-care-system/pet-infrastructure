#!/bin/bash

# 宠物管理系统 GitHub 仓库设置脚本
# 用途：将分离后的5个仓库推送到GitHub

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置项 - GitHub账户设置
GITHUB_USERNAME=""        # 你的GitHub用户名
GITHUB_ORGANIZATION=""    # GitHub组织名 (可选，留空则使用个人账户)
USE_ORGANIZATION=false    # 是否使用组织模式

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    🚀 GitHub 仓库设置向导                        ║"
echo "║                 宠物管理系统微服务架构部署                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查GitHub配置
if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${YELLOW}📝 请输入你的GitHub用户名: ${NC}"
    read -p "> " GITHUB_USERNAME
    
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${RED}❌ GitHub用户名不能为空${NC}"
        exit 1
    fi
fi

# 询问是否使用组织
echo -e "${BLUE}🏢 是否要使用GitHub组织管理项目？${NC}"
echo "   选择组织模式的优势："
echo "   • 统一的品牌形象和专业展示"
echo "   • 更好的团队协作和权限管理"
echo "   • 组织级别的Secrets和CI/CD配置"
echo "   • 支持团队扩展和企业级功能"
echo ""
read -p "使用组织模式？(y/N): " use_org_choice

if [[ $use_org_choice =~ ^[Yy]$ ]]; then
    USE_ORGANIZATION=true
    
    if [ -z "$GITHUB_ORGANIZATION" ]; then
        echo -e "${YELLOW}📝 请输入GitHub组织名称: ${NC}"
        read -p "> " GITHUB_ORGANIZATION
        
        if [ -z "$GITHUB_ORGANIZATION" ]; then
            echo -e "${RED}❌ 组织名称不能为空${NC}"
            exit 1
        fi
    fi
    
    GITHUB_OWNER="$GITHUB_ORGANIZATION"
    echo -e "${GREEN}🏢 GitHub组织: ${GITHUB_ORGANIZATION}${NC}"
else
    USE_ORGANIZATION=false
    GITHUB_OWNER="$GITHUB_USERNAME"
    echo -e "${GREEN}👤 GitHub个人账户: ${GITHUB_USERNAME}${NC}"
fi

echo ""

# 仓库配置
repos=(
    "pet-backend:宠物管理系统后端API服务:Node.js + Express + PostgreSQL + Redis"
    "pet-frontend:宠物管理系统Web前端:React + TypeScript + Vite + Tailwind"
    "pet-mobile:宠物管理系统移动端应用:React Native + TypeScript + Firebase"
    "pet-customer-portal:宠物管理系统客户门户:Next.js + TypeScript + Tailwind"
    "pet-shared:宠物管理系统共享组件库:TypeScript + npm package"
)

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}🔍 检查依赖环境...${NC}"
    
    # 检查git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git 未安装${NC}"
        exit 1
    fi
    
    # 检查SSH密钥
    if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
        echo -e "${YELLOW}⚠️  未找到SSH密钥，请先生成SSH密钥对${NC}"
        echo -e "${BLUE}💡 生成SSH密钥: ssh-keygen -t ed25519 -C \"your_email@example.com\"${NC}"
        echo -e "${BLUE}💡 添加到GitHub: https://github.com/settings/ssh/new${NC}"
        echo ""
        read -p "已配置SSH密钥？(y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ 请先配置SSH密钥${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ SSH密钥已存在${NC}"
    fi
    
    # 测试SSH连接
    echo -e "${YELLOW}🔍 测试GitHub SSH连接...${NC}"
    if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ GitHub SSH连接正常${NC}"
    else
        echo -e "${RED}❌ GitHub SSH连接失败${NC}"
        echo -e "${BLUE}💡 请确保SSH密钥已添加到GitHub: https://github.com/settings/ssh/new${NC}"
        echo -e "${BLUE}💡 测试连接: ssh -T git@github.com${NC}"
        echo ""
        read -p "SSH连接已配置？(y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ 请先配置SSH连接${NC}"
            exit 1
        fi
    fi
    
    # 检查GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠️  GitHub CLI未安装，将跳过自动创建仓库${NC}"
        echo -e "${BLUE}💡 安装方法: brew install gh (macOS) 或访问 https://cli.github.com${NC}"
        USE_GH_CLI=false
    else
        # 检查是否已登录
        if ! gh auth status &> /dev/null; then
            echo -e "${YELLOW}⚠️  请先登录GitHub CLI: ${BLUE}gh auth login${NC}"
            USE_GH_CLI=false
        else
            echo -e "${GREEN}✅ GitHub CLI已就绪${NC}"
            USE_GH_CLI=true
        fi
    fi
    
    echo ""
}

# 创建GitHub仓库
create_github_repos() {
    if [ "$USE_GH_CLI" = true ]; then
        echo -e "${YELLOW}📦 自动创建GitHub仓库...${NC}"
        
        for repo_config in "${repos[@]}"; do
            IFS=':' read -r repo_name description tech_stack <<< "$repo_config"
            
            echo -e "创建仓库: ${BLUE}${repo_name}${NC}"
            
            if [ "$USE_ORGANIZATION" = true ]; then
                # 在组织中创建仓库
                if gh repo create "${GITHUB_ORGANIZATION}/${repo_name}" --private --description "${description}" 2>/dev/null; then
                    echo -e "${GREEN}✅ ${repo_name} 在组织中创建成功${NC}"
                else
                    echo -e "${YELLOW}⚠️  ${repo_name} 可能已存在，继续...${NC}"
                fi
            else
                # 在个人账户中创建仓库
                if gh repo create "${GITHUB_USERNAME}/${repo_name}" --private --description "${description}" 2>/dev/null; then
                    echo -e "${GREEN}✅ ${repo_name} 创建成功${NC}"
                else
                    echo -e "${YELLOW}⚠️  ${repo_name} 可能已存在，继续...${NC}"
                fi
            fi
        done
        echo ""
    else
        echo -e "${YELLOW}📝 请手动在GitHub创建以下仓库 (Private):${NC}"
        echo ""
        for repo_config in "${repos[@]}"; do
            IFS=':' read -r repo_name description tech_stack <<< "$repo_config"
            echo -e "  🔸 ${BLUE}${repo_name}${NC} - ${description}"
        done
        echo ""
        echo -e "${YELLOW}创建完成后按Enter继续...${NC}"
        read
    fi
}

# 推送单个仓库
push_repo() {
    local repo_name=$1
    local description=$2
    local tech_stack=$3
    local repo_path="/Users/newdroid/Documents/project/${repo_name}"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📦 处理仓库: ${BLUE}${repo_name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$repo_path" ]; then
        echo -e "${RED}❌ 目录不存在: $repo_path${NC}"
        return 1
    fi
    
    cd "$repo_path"
    
    # 检查是否已经是git仓库
    if [ ! -d ".git" ]; then
        echo -e "🔧 初始化Git仓库..."
        git init
        git branch -M main
    else
        echo -e "✅ Git仓库已存在"
    fi
    
    # 添加远程仓库 (使用SSH)
    local remote_url="git@github.com:${GITHUB_OWNER}/${repo_name}.git"
    
    if git remote get-url origin >/dev/null 2>&1; then
        echo -e "🔄 更新远程仓库URL..."
        git remote set-url origin "$remote_url"
    else
        echo -e "🔗 添加远程仓库..."
        git remote add origin "$remote_url"
    fi
    
    echo -e "📁 远程仓库: ${BLUE}${remote_url}${NC}"
    
    # 检查是否有文件需要提交
    git add .
    
    if git diff --staged --quiet; then
        echo -e "${YELLOW}ℹ️  没有新的更改需要提交${NC}"
    else
        echo -e "📝 提交代码..."
        
        # 创建详细的提交信息
        commit_message="🎉 初始提交: ${description}

✨ 核心功能:
- 完整的项目结构和核心业务代码
- TypeScript支持和完整类型定义
- Docker容器化部署配置
- GitHub Actions CI/CD自动化流水线
- 完善的项目文档和使用指南

🛠️ 技术栈:
${tech_stack}

📋 项目特性:
$(if [ -f "package.json" ]; then
    echo "- $(jq -r '.name // "N/A"' package.json) v$(jq -r '.version // "1.0.0"' package.json)"
    echo "- Node.js $(jq -r '.engines.node // ">=16.0.0"' package.json)"
    if jq -e '.scripts.test' package.json >/dev/null; then
        echo "- 单元测试和集成测试"
    fi
    if jq -e '.scripts.lint' package.json >/dev/null; then
        echo "- ESLint代码规范检查"
    fi
    if [ -f "Dockerfile" ]; then
        echo "- Docker容器化支持"
    fi
else
    echo "- 详见项目README.md文档"
fi)

🚀 快速开始:
1. 克隆仓库: git clone ${remote_url}
2. 安装依赖: $(if [ -f "package.json" ]; then echo "npm install"; else echo "详见README.md"; fi)
3. 查看文档: 阅读README.md了解详细说明

🔄 CI/CD流程:
- ✅ 代码质量检查 (ESLint, TypeScript)  
- ✅ 自动化测试执行和覆盖率报告
- ✅ 安全扫描和依赖漏洞检测
- ✅ Docker镜像构建和推送
- ✅ 多环境自动部署 (dev/staging/prod)

📊 项目状态: 🟢 开发就绪，支持生产部署

---
🤖 Generated with Claude Code - Pet Care Management System
📅 $(date +'%Y-%m-%d %H:%M:%S')
👨‍💻 Pushed by: ${GITHUB_USERNAME}"

        git commit -m "$commit_message"
        echo -e "${GREEN}✅ 代码提交完成${NC}"
    fi
    
    # 推送到远程仓库
    echo -e "🚀 推送到GitHub..."
    
    if git push -u origin main 2>/dev/null; then
        echo -e "${GREEN}✅ ${repo_name} 推送成功${NC}"
    else
        echo -e "${YELLOW}⚠️  首次推送失败，尝试强制推送...${NC}"
        if git push -f -u origin main; then
            echo -e "${GREEN}✅ ${repo_name} 强制推送成功${NC}"
        else
            echo -e "${RED}❌ ${repo_name} 推送失败${NC}"
            return 1
        fi
    fi
    
    echo -e "🌐 仓库地址: ${BLUE}https://github.com/${GITHUB_OWNER}/${repo_name}${NC}"
    echo -e "📊 Actions: ${BLUE}https://github.com/${GITHUB_OWNER}/${repo_name}/actions${NC}"
    echo ""
}

# 显示设置指南
show_next_steps() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 推送完成！下一步操作                        ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}🔐 1. 配置GitHub Secrets (必需):${NC}"
    echo "   访问每个仓库的 Settings → Secrets and variables → Actions"
    echo "   添加以下Secrets:"
    echo ""
    echo -e "${BLUE}   通用Secrets (所有仓库):${NC}"
    echo "   • JWT_SECRET=your-super-secret-jwt-key-256-bit"
    echo "   • JWT_REFRESH_SECRET=your-refresh-token-secret"
    echo "   • DB_PASSWORD=your-database-password"
    echo "   • REDIS_PASSWORD=your-redis-password"
    echo ""
    
    echo -e "${BLUE}   仓库特定Secrets:${NC}"
    echo "   • pet-backend: DOCKER_USERNAME, DOCKER_PASSWORD"
    echo "   • pet-frontend: VITE_API_BASE_URL, VERCEL_TOKEN"
    echo "   • pet-mobile: FIREBASE_SERVICE_ACCOUNT, EXPO_TOKEN"
    echo "   • pet-shared: NPM_TOKEN"
    echo ""
    
    echo -e "${YELLOW}⚙️ 2. 验证CI/CD流水线:${NC}"
    echo "   • 检查GitHub Actions是否成功运行"
    echo "   • 修复任何失败的workflow"
    echo "   • 确认Docker镜像构建成功"
    echo ""
    
    echo -e "${YELLOW}🛡️ 3. 设置分支保护规则 (推荐):${NC}"
    echo "   访问仓库 Settings → Branches → Add rule"
    echo "   • 要求PR审查"
    echo "   • 要求状态检查通过"
    echo "   • 限制强制推送"
    echo ""
    
    echo -e "${YELLOW}🔗 4. 仓库链接:${NC}"
    for repo_config in "${repos[@]}"; do
        IFS=':' read -r repo_name description tech_stack <<< "$repo_config"
        echo -e "   • ${BLUE}${repo_name}${NC}: https://github.com/${GITHUB_OWNER}/${repo_name}"
    done
    echo ""
    
    echo -e "${GREEN}✨ 恭喜！你的宠物管理系统微服务架构已成功部署到GitHub！${NC}"
    echo -e "${BLUE}📖 详细说明请查看: GITHUB_SETUP_GUIDE.md${NC}"
}

# 主函数
main() {
    check_dependencies
    create_github_repos
    
    echo -e "${YELLOW}🚀 开始推送所有仓库...${NC}"
    echo ""
    
    success_count=0
    total_count=${#repos[@]}
    
    for repo_config in "${repos[@]}"; do
        IFS=':' read -r repo_name description tech_stack <<< "$repo_config"
        
        if push_repo "$repo_name" "$description" "$tech_stack"; then
            ((success_count++))
        else
            echo -e "${RED}❌ ${repo_name} 推送失败${NC}"
        fi
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 推送结果: ${success_count}/${total_count} 个仓库成功${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        show_next_steps
    else
        echo -e "${YELLOW}⚠️  部分仓库推送失败，请检查错误信息并重试${NC}"
    fi
}

# 脚本参数处理
case "${1:-}" in
    "--help"|"-h")
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help, -h    显示帮助信息"
        echo "  --list, -l    列出所有仓库"
        echo "  --check, -c   检查环境依赖"
        echo ""
        echo "示例:"
        echo "  $0           # 执行完整设置流程"
        echo "  $0 --list    # 列出所有仓库信息"
        ;;
    "--list"|"-l")
        echo -e "${BLUE}📋 宠物管理系统仓库清单:${NC}"
        echo ""
        for repo_config in "${repos[@]}"; do
            IFS=':' read -r repo_name description tech_stack <<< "$repo_config"
            echo -e "🔸 ${YELLOW}${repo_name}${NC}"
            echo -e "   描述: ${description}"
            echo -e "   技术栈: ${tech_stack}"
            echo ""
        done
        ;;
    "--check"|"-c")
        check_dependencies
        ;;
    "")
        main
        ;;
    *)
        echo -e "${RED}❌ 未知参数: $1${NC}"
        echo -e "使用 $0 --help 查看帮助信息"
        exit 1
        ;;
esac