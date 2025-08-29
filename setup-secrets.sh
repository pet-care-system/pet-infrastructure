#!/bin/bash

# GitHub Secrets 配置脚本
# 用途：为所有仓库批量配置必要的Secrets

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置项
GITHUB_USERNAME=""        # 你的GitHub用户名
GITHUB_ORGANIZATION=""    # GitHub组织名 (可选)
USE_ORGANIZATION=false    # 是否使用组织模式

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                   🔐 GitHub Secrets 配置向导                     ║"
echo "║                     安全密钥批量配置工具                          ║"
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
echo -e "${BLUE}🏢 是否要为GitHub组织配置Secrets？${NC}"
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
    echo -e "${GREEN}🏢 将为组织配置Secrets: ${GITHUB_ORGANIZATION}${NC}"
    echo -e "${BLUE}💡 组织Secrets将被所有仓库共享，更高效！${NC}"
else
    USE_ORGANIZATION=false
    GITHUB_OWNER="$GITHUB_USERNAME"
    echo -e "${GREEN}👤 将为个人仓库配置Secrets${NC}"
fi

# 检查GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI 未安装${NC}"
    echo -e "${BLUE}💡 安装方法: brew install gh (macOS) 或访问 https://cli.github.com${NC}"
    exit 1
fi

# 检查是否已登录
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  请先登录GitHub CLI: ${BLUE}gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}👤 GitHub用户: ${GITHUB_USERNAME}${NC}"
if [ "$USE_ORGANIZATION" = true ]; then
    echo -e "${GREEN}🏢 目标组织: ${GITHUB_ORGANIZATION}${NC}"
fi
echo -e "${GREEN}✅ GitHub CLI已就绪${NC}"
echo ""

# 仓库列表
repos=("pet-backend" "pet-frontend" "pet-mobile" "pet-customer-portal" "pet-shared")

# 收集Secrets值
collect_secrets() {
    echo -e "${YELLOW}📋 配置通用Secrets (所有仓库都需要):${NC}"
    echo ""
    
    # JWT_SECRET
    echo -e "${BLUE}🔑 JWT_SECRET${NC} - JWT令牌签名密钥 (建议256位)"
    echo "   示例: $(openssl rand -hex 32 2>/dev/null || echo "your-super-secret-jwt-key-256-bit")"
    read -p "请输入JWT_SECRET: " JWT_SECRET
    echo ""
    
    # JWT_REFRESH_SECRET
    echo -e "${BLUE}🔑 JWT_REFRESH_SECRET${NC} - 刷新令牌签名密钥"
    echo "   示例: $(openssl rand -hex 32 2>/dev/null || echo "your-refresh-token-secret-key")"
    read -p "请输入JWT_REFRESH_SECRET: " JWT_REFRESH_SECRET
    echo ""
    
    # DB_PASSWORD
    echo -e "${BLUE}🗄️  DB_PASSWORD${NC} - 数据库密码"
    echo -s "请输入数据库密码: "
    read DB_PASSWORD
    echo ""
    echo ""
    
    # REDIS_PASSWORD
    echo -e "${BLUE}📊 REDIS_PASSWORD${NC} - Redis缓存密码"
    echo -s "请输入Redis密码: "
    read REDIS_PASSWORD
    echo ""
    echo ""
    
    # 可选的特定仓库Secrets
    echo -e "${YELLOW}📋 配置特定仓库Secrets (可选，回车跳过):${NC}"
    echo ""
    
    # Docker Hub
    echo -e "${BLUE}🐳 Docker Hub配置 (用于pet-backend)${NC}"
    read -p "Docker Hub用户名: " DOCKER_USERNAME
    if [ -n "$DOCKER_USERNAME" ]; then
        echo -s "Docker Hub密码: "
        read DOCKER_PASSWORD
        echo ""
    fi
    echo ""
    
    # Vercel Token
    echo -e "${BLUE}⚡ Vercel Token (用于前端部署)${NC}"
    read -p "Vercel Token: " VERCEL_TOKEN
    echo ""
    
    # NPM Token
    echo -e "${BLUE}📦 NPM Token (用于pet-shared包发布)${NC}"
    read -p "NPM Token: " NPM_TOKEN
    echo ""
}

# 设置组织级secrets
setup_org_secrets() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🏢 配置组织 ${GITHUB_ORGANIZATION} 的Secrets...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 设置组织级通用secrets
    local common_secrets=(
        "JWT_SECRET:${JWT_SECRET}"
        "JWT_REFRESH_SECRET:${JWT_REFRESH_SECRET}"
        "DB_PASSWORD:${DB_PASSWORD}"
        "REDIS_PASSWORD:${REDIS_PASSWORD}"
    )
    
    for secret in "${common_secrets[@]}"; do
        IFS=':' read -r name value <<< "$secret"
        if [ -n "$value" ]; then
            echo -e "  设置组织级 ${BLUE}${name}${NC}..."
            if echo "$value" | gh secret set "$name" --org "$GITHUB_ORGANIZATION"; then
                echo -e "  ${GREEN}✅ ${name} 设置成功${NC}"
            else
                echo -e "  ${RED}❌ ${name} 设置失败${NC}"
            fi
        fi
    done
    
    # 设置其他组织级secrets
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        echo -e "  设置组织级 ${BLUE}DOCKER_USERNAME${NC}..."
        echo "$DOCKER_USERNAME" | gh secret set "DOCKER_USERNAME" --org "$GITHUB_ORGANIZATION"
        echo -e "  设置组织级 ${BLUE}DOCKER_PASSWORD${NC}..."
        echo "$DOCKER_PASSWORD" | gh secret set "DOCKER_PASSWORD" --org "$GITHUB_ORGANIZATION"
        echo -e "  ${GREEN}✅ Docker组织配置设置成功${NC}"
    fi
    
    if [ -n "$NPM_TOKEN" ]; then
        echo -e "  设置组织级 ${BLUE}NPM_TOKEN${NC}..."
        echo "$NPM_TOKEN" | gh secret set "NPM_TOKEN" --org "$GITHUB_ORGANIZATION"
        echo -e "  ${GREEN}✅ NPM Token设置成功${NC}"
    fi
    
    echo -e "${GREEN}🎉 组织级Secrets配置完成！所有仓库都可以使用这些Secrets${NC}"
    echo ""
}

# 设置单个仓库的secrets
setup_repo_secrets() {
    local repo=$1
    local repo_full="${GITHUB_OWNER}/${repo}"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔐 配置 ${repo} 的Secrets...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 检查仓库是否存在
    if ! gh repo view "$repo_full" >/dev/null 2>&1; then
        echo -e "${RED}❌ 仓库 ${repo_full} 不存在或无权限访问${NC}"
        return 1
    fi
    
    # 如果使用组织模式，跳过通用secrets（组织级已设置）
    if [ "$USE_ORGANIZATION" = false ]; then
        # 设置通用secrets（仅个人账户模式）
        local common_secrets=(
            "JWT_SECRET:${JWT_SECRET}"
            "JWT_REFRESH_SECRET:${JWT_REFRESH_SECRET}"
            "DB_PASSWORD:${DB_PASSWORD}"
            "REDIS_PASSWORD:${REDIS_PASSWORD}"
        )
        
        for secret in "${common_secrets[@]}"; do
            IFS=':' read -r name value <<< "$secret"
            if [ -n "$value" ]; then
                echo -e "  设置 ${BLUE}${name}${NC}..."
                if echo "$value" | gh secret set "$name" --repo "$repo_full"; then
                    echo -e "  ${GREEN}✅ ${name} 设置成功${NC}"
                else
                    echo -e "  ${RED}❌ ${name} 设置失败${NC}"
                fi
            fi
        done
    else
        echo -e "  ${BLUE}ℹ️  通用Secrets已在组织级别配置，跳过重复设置${NC}"
    fi
    
    # 设置仓库特定secrets
    case "$repo" in
        "pet-backend")
            if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
                echo -e "  设置 ${BLUE}DOCKER_USERNAME${NC}..."
                echo "$DOCKER_USERNAME" | gh secret set "DOCKER_USERNAME" --repo "$repo_full"
                echo -e "  设置 ${BLUE}DOCKER_PASSWORD${NC}..."
                echo "$DOCKER_PASSWORD" | gh secret set "DOCKER_PASSWORD" --repo "$repo_full"
                echo -e "  ${GREEN}✅ Docker配置设置成功${NC}"
            fi
            ;;
        "pet-frontend")
            if [ -n "$VERCEL_TOKEN" ]; then
                echo -e "  设置 ${BLUE}VERCEL_TOKEN${NC}..."
                echo "$VERCEL_TOKEN" | gh secret set "VERCEL_TOKEN" --repo "$repo_full"
                echo -e "  ${GREEN}✅ Vercel Token设置成功${NC}"
            fi
            # 设置API地址
            echo -e "  设置 ${BLUE}VITE_API_BASE_URL${NC}..."
            echo "https://api.petcare.com/api" | gh secret set "VITE_API_BASE_URL" --repo "$repo_full"
            echo -e "  设置 ${BLUE}VITE_AUTH_BASE_URL${NC}..."
            echo "https://api.petcare.com" | gh secret set "VITE_AUTH_BASE_URL" --repo "$repo_full"
            ;;
        "pet-customer-portal")
            if [ -n "$VERCEL_TOKEN" ]; then
                echo -e "  设置 ${BLUE}VERCEL_TOKEN${NC}..."
                echo "$VERCEL_TOKEN" | gh secret set "VERCEL_TOKEN" --repo "$repo_full"
            fi
            # 设置API地址
            echo -e "  设置 ${BLUE}NEXT_PUBLIC_API_URL${NC}..."
            echo "https://api.petcare.com/api" | gh secret set "NEXT_PUBLIC_API_URL" --repo "$repo_full"
            ;;
        "pet-shared")
            if [ -n "$NPM_TOKEN" ]; then
                echo -e "  设置 ${BLUE}NPM_TOKEN${NC}..."
                echo "$NPM_TOKEN" | gh secret set "NPM_TOKEN" --repo "$repo_full"
                echo -e "  ${GREEN}✅ NPM Token设置成功${NC}"
            fi
            ;;
        "pet-mobile")
            echo -e "  ${YELLOW}ℹ️  移动端Secrets需要手动配置以下项目:${NC}"
            echo -e "    • FIREBASE_SERVICE_ACCOUNT (Firebase服务账号JSON)"
            echo -e "    • EXPO_TOKEN (Expo发布token)"
            echo -e "    • APPLE_CERTIFICATE (iOS证书)"
            echo -e "    • ANDROID_KEYSTORE (Android密钥库)"
            ;;
    esac
    
    echo ""
}

# 验证secrets设置
verify_secrets() {
    echo -e "${YELLOW}🔍 验证Secrets设置...${NC}"
    echo ""
    
    for repo in "${repos[@]}"; do
        local repo_full="${GITHUB_USERNAME}/${repo}"
        echo -e "${BLUE}📋 ${repo} 的Secrets:${NC}"
        
        if gh secret list --repo "$repo_full" 2>/dev/null; then
            echo -e "${GREEN}✅ ${repo} Secrets列表获取成功${NC}"
        else
            echo -e "${RED}❌ ${repo} Secrets列表获取失败${NC}"
        fi
        echo ""
    done
}

# 显示手动配置指南
show_manual_guide() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                     📖 手动配置指南                              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}🚀 某些Secrets需要手动配置:${NC}"
    echo ""
    
    echo -e "${BLUE}📱 pet-mobile 仓库:${NC}"
    echo "   1. 访问 https://github.com/${GITHUB_USERNAME}/pet-mobile/settings/secrets/actions"
    echo "   2. 添加以下Secrets:"
    echo "      • FIREBASE_SERVICE_ACCOUNT: Firebase服务账号JSON内容"
    echo "      • EXPO_TOKEN: 从 https://expo.dev 获取"
    echo "      • APPLE_CERTIFICATE: iOS开发证书 (Base64编码)"
    echo "      • ANDROID_KEYSTORE: Android密钥库文件 (Base64编码)"
    echo ""
    
    echo -e "${BLUE}🔧 其他配置项:${NC}"
    echo "   • 根据实际部署环境调整API地址"
    echo "   • 配置生产环境的数据库连接"
    echo "   • 设置邮件服务和第三方服务密钥"
    echo ""
    
    echo -e "${YELLOW}🔗 有用的链接:${NC}"
    echo "   • GitHub Secrets文档: https://docs.github.com/en/actions/security-guides/encrypted-secrets"
    echo "   • 密钥生成工具: https://www.allkeysgenerator.com/Random/Security-Encryption-Key-Generator.aspx"
    echo "   • JWT密钥检查: https://jwt.io/"
    echo ""
}

# 主函数
main() {
    collect_secrets
    
    echo -e "${YELLOW}🚀 开始配置Secrets...${NC}"
    echo ""
    
    # 如果使用组织模式，先设置组织级Secrets
    if [ "$USE_ORGANIZATION" = true ]; then
        setup_org_secrets
    fi
    
    success_count=0
    total_count=${#repos[@]}
    
    for repo in "${repos[@]}"; do
        if setup_repo_secrets "$repo"; then
            ((success_count++))
        fi
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 配置结果: ${success_count}/${total_count} 个仓库成功${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    verify_secrets
    show_manual_guide
    
    echo -e "${GREEN}🎉 Secrets配置完成！现在可以验证CI/CD流水线了${NC}"
}

# 脚本参数处理
case "${1:-}" in
    "--help"|"-h")
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help, -h      显示帮助信息"
        echo "  --verify, -v    仅验证现有Secrets"
        echo "  --guide, -g     显示手动配置指南"
        echo ""
        echo "示例:"
        echo "  $0              # 执行完整配置流程"
        echo "  $0 --verify     # 验证现有配置"
        ;;
    "--verify"|"-v")
        if [ -z "$GITHUB_USERNAME" ]; then
            echo -e "${YELLOW}📝 请输入你的GitHub用户名: ${NC}"
            read -p "> " GITHUB_USERNAME
        fi
        verify_secrets
        ;;
    "--guide"|"-g")
        if [ -z "$GITHUB_USERNAME" ]; then
            echo -e "${YELLOW}📝 请输入你的GitHub用户名: ${NC}"
            read -p "> " GITHUB_USERNAME
        fi
        show_manual_guide
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