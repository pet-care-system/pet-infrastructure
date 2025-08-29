#!/bin/bash

# GitHub组织迁移脚本
# 用途：将现有个人仓库迁移到组织

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置项
GITHUB_USERNAME=""        # 你的GitHub用户名  
GITHUB_ORGANIZATION=""    # 目标组织名

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                   🔄 GitHub组织迁移向导                          ║"
echo "║                   将仓库迁移到GitHub组织                          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 获取用户输入
get_user_input() {
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${YELLOW}📝 请输入你的GitHub用户名: ${NC}"
        read -p "> " GITHUB_USERNAME
        
        if [ -z "$GITHUB_USERNAME" ]; then
            echo -e "${RED}❌ GitHub用户名不能为空${NC}"
            exit 1
        fi
    fi
    
    if [ -z "$GITHUB_ORGANIZATION" ]; then
        echo -e "${YELLOW}📝 请输入目标GitHub组织名: ${NC}"
        read -p "> " GITHUB_ORGANIZATION
        
        if [ -z "$GITHUB_ORGANIZATION" ]; then
            echo -e "${RED}❌ 组织名不能为空${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}👤 源账户: ${GITHUB_USERNAME}${NC}"
    echo -e "${GREEN}🏢 目标组织: ${GITHUB_ORGANIZATION}${NC}"
    echo ""
}

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}🔍 检查依赖环境...${NC}"
    
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
    
    echo -e "${GREEN}✅ GitHub CLI已就绪${NC}"
    echo ""
}

# 验证组织权限
verify_org_access() {
    echo -e "${YELLOW}🔍 验证组织权限...${NC}"
    
    # 检查组织是否存在以及用户是否有权限
    if gh api orgs/"$GITHUB_ORGANIZATION" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 组织存在且有权限访问${NC}"
    else
        echo -e "${RED}❌ 无法访问组织 ${GITHUB_ORGANIZATION}${NC}"
        echo -e "${BLUE}💡 请确保：${NC}"
        echo -e "   • 组织名拼写正确"
        echo -e "   • 你是组织的所有者或管理员"
        echo -e "   • 组织允许仓库转移"
        exit 1
    fi
    
    # 检查组织设置
    echo -e "${BLUE}📋 组织信息:${NC}"
    gh api orgs/"$GITHUB_ORGANIZATION" --jq '{name, description, public_repos, private_repos}' | while IFS= read -r line; do
        echo -e "   $line"
    done
    echo ""
}

# 仓库列表
repos=("pet-backend" "pet-frontend" "pet-mobile" "pet-customer-portal" "pet-shared")

# 检查现有仓库
check_existing_repos() {
    echo -e "${YELLOW}🔍 检查现有仓库...${NC}"
    echo ""
    
    existing_repos=()
    missing_repos=()
    
    for repo in "${repos[@]}"; do
        if gh repo view "$GITHUB_USERNAME/$repo" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ ${repo}${NC} - 存在于个人账户"
            existing_repos+=("$repo")
        else
            echo -e "  ${RED}❌ ${repo}${NC} - 不存在或无权限访问"
            missing_repos+=("$repo")
        fi
    done
    
    echo ""
    
    if [ ${#missing_repos[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  以下仓库不存在或无权限访问:${NC}"
        for repo in "${missing_repos[@]}"; do
            echo -e "   • $repo"
        done
        echo ""
        
        read -p "是否继续迁移现有仓库？(y/N): " continue_migration
        if [[ ! $continue_migration =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}ℹ️  迁移已取消${NC}"
            exit 0
        fi
    fi
    
    if [ ${#existing_repos[@]} -eq 0 ]; then
        echo -e "${RED}❌ 没有找到可迁移的仓库${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}📊 将迁移 ${#existing_repos[@]} 个仓库${NC}"
    echo ""
}

# 迁移单个仓库
migrate_repo() {
    local repo=$1
    local source_repo="$GITHUB_USERNAME/$repo"
    local target_repo="$GITHUB_ORGANIZATION/$repo"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📦 迁移仓库: ${repo}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 检查目标仓库是否已存在
    if gh repo view "$target_repo" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  目标仓库已存在: ${target_repo}${NC}"
        read -p "是否覆盖？(y/N): " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}ℹ️  跳过 ${repo}${NC}"
            return 0
        fi
    fi
    
    # 执行仓库转移
    echo -e "🔄 转移仓库到组织..."
    
    if gh api repos/"$source_repo"/transfer \
        --method POST \
        --field new_owner="$GITHUB_ORGANIZATION" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ${repo} 迁移成功${NC}"
        
        # 等待几秒确保迁移完成
        sleep 2
        
        # 验证迁移结果
        if gh repo view "$target_repo" >/dev/null 2>&1; then
            echo -e "   📍 新地址: https://github.com/${target_repo}"
            echo -e "   🔗 SSH: git@github.com:${target_repo}.git"
        else
            echo -e "${YELLOW}⚠️  迁移可能仍在进行中...${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ ${repo} 迁移失败${NC}"
        echo -e "${BLUE}💡 可能原因：${NC}"
        echo -e "   • 权限不足"
        echo -e "   • 组织设置限制"
        echo -e "   • 网络问题"
        return 1
    fi
    
    echo ""
}

# 更新本地仓库远程URL
update_local_remotes() {
    echo -e "${YELLOW}🔄 是否更新本地仓库的远程URL？${NC}"
    read -p "(y/N): " update_remotes
    
    if [[ ! $update_remotes =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  跳过本地更新${NC}"
        return 0
    fi
    
    local base_path="/Users/newdroid/Documents/project"
    
    echo -e "${YELLOW}📝 请输入项目基础路径 (默认: ${base_path}): ${NC}"
    read -p "> " input_path
    
    if [ -n "$input_path" ]; then
        base_path="$input_path"
    fi
    
    if [ ! -d "$base_path" ]; then
        echo -e "${RED}❌ 路径不存在: $base_path${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔄 更新本地仓库远程URL...${NC}"
    echo ""
    
    for repo in "${existing_repos[@]}"; do
        local repo_path="$base_path/$repo"
        
        if [ -d "$repo_path/.git" ]; then
            echo -e "  更新 ${BLUE}${repo}${NC}..."
            cd "$repo_path"
            
            # 更新远程URL
            git remote set-url origin "git@github.com:${GITHUB_ORGANIZATION}/${repo}.git"
            
            # 验证更新
            local current_url=$(git remote get-url origin)
            echo -e "    新URL: $current_url"
            
            echo -e "  ${GREEN}✅ ${repo} URL已更新${NC}"
        else
            echo -e "  ${YELLOW}⚠️  ${repo} - 本地仓库不存在${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 本地仓库URL更新完成${NC}"
}

# 显示迁移后的设置建议
show_post_migration_guide() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 迁移完成！下一步设置                       ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}🔧 建议的后续操作:${NC}"
    echo ""
    
    echo -e "${BLUE}1. 配置组织设置:${NC}"
    echo -e "   • 访问 https://github.com/orgs/${GITHUB_ORGANIZATION}/settings"
    echo -e "   • 配置成员权限和仓库默认权限"
    echo -e "   • 设置分支保护规则"
    echo -e "   • 启用安全功能 (Dependabot, Secret Scanning)"
    echo ""
    
    echo -e "${BLUE}2. 配置团队和权限:${NC}"
    echo -e "   • 创建开发团队 (core-team, mobile-team, product-team)"
    echo -e "   • 分配仓库访问权限"
    echo -e "   • 设置团队成员角色"
    echo ""
    
    echo -e "${BLUE}3. 配置组织级Secrets:${NC}"
    echo -e "   • 运行: ${GREEN}./setup-secrets.sh${NC}"
    echo -e "   • 配置组织共享的环境变量"
    echo -e "   • 减少重复配置"
    echo ""
    
    echo -e "${BLUE}4. 更新CI/CD配置:${NC}"
    echo -e "   • 检查GitHub Actions是否正常运行"
    echo -e "   • 更新workflow中的仓库引用"
    echo -e "   • 验证组织级Secrets可用性"
    echo ""
    
    echo -e "${BLUE}5. 团队协作配置:${NC}"
    echo -e "   • 邀请团队成员到组织"
    echo -e "   • 设置代码审查规则"
    echo -e "   • 配置通知和集成"
    echo ""
    
    echo -e "${YELLOW}🔗 有用的链接:${NC}"
    echo -e "   • 组织设置: https://github.com/orgs/${GITHUB_ORGANIZATION}/settings"
    echo -e "   • 团队管理: https://github.com/orgs/${GITHUB_ORGANIZATION}/teams"
    echo -e "   • Secrets设置: https://github.com/orgs/${GITHUB_ORGANIZATION}/settings/secrets/actions"
    echo -e "   • 安全设置: https://github.com/orgs/${GITHUB_ORGANIZATION}/settings/security_analysis"
    echo ""
    
    echo -e "${GREEN}✨ 恭喜！宠物管理系统已成功迁移到GitHub组织！${NC}"
    echo -e "${BLUE}📖 详细组织管理指南请查看: ORGANIZATION_SETUP_GUIDE.md${NC}"
}

# 主函数
main() {
    get_user_input
    check_dependencies
    verify_org_access
    check_existing_repos
    
    echo -e "${YELLOW}🚀 开始迁移仓库...${NC}"
    echo ""
    
    success_count=0
    total_count=${#existing_repos[@]}
    
    for repo in "${existing_repos[@]}"; do
        if migrate_repo "$repo"; then
            ((success_count++))
        fi
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 迁移结果: ${success_count}/${total_count} 个仓库成功${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ $success_count -gt 0 ]; then
        update_local_remotes
        show_post_migration_guide
    else
        echo -e "${RED}❌ 迁移失败，请检查错误信息并重试${NC}"
    fi
}

# 脚本参数处理
case "${1:-}" in
    "--help"|"-h")
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help, -h      显示帮助信息"
        echo "  --check, -c     仅检查仓库状态"
        echo ""
        echo "示例:"
        echo "  $0              # 执行完整迁移流程"
        echo "  $0 --check      # 检查仓库状态"
        ;;
    "--check"|"-c")
        get_user_input
        check_dependencies
        verify_org_access
        check_existing_repos
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