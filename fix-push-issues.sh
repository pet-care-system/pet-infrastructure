#!/bin/bash

# GitHub推送问题修复脚本
# 用途：修复推送失败的仓库

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                   🔧 GitHub推送问题修复工具                      ║"
echo "║                     解决推送失败的常见问题                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 配置
GITHUB_OWNER="pet-care-system"  # 根据你的实际情况修改
FAILED_REPO="pet-shared"
BASE_PATH="/Users/newdroid/Documents/project"

# 修复单个仓库推送问题
fix_repo_push() {
    local repo_name=$1
    local repo_path="${BASE_PATH}/${repo_name}"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔧 修复仓库: ${repo_name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$repo_path" ]; then
        echo -e "${RED}❌ 仓库路径不存在: $repo_path${NC}"
        return 1
    fi
    
    cd "$repo_path"
    
    # 检查Git状态
    echo -e "${YELLOW}🔍 检查Git仓库状态...${NC}"
    
    if [ ! -d ".git" ]; then
        echo -e "${RED}❌ 不是Git仓库${NC}"
        return 1
    fi
    
    # 显示当前状态
    echo -e "${BLUE}📊 当前Git状态:${NC}"
    git status --porcelain
    
    # 检查分支
    echo -e "${YELLOW}🌿 检查分支状态...${NC}"
    local current_branch=$(git branch --show-current 2>/dev/null || echo "")
    local all_branches=$(git branch -a 2>/dev/null || echo "")
    
    echo -e "${BLUE}当前分支: ${current_branch:-"detached HEAD"}${NC}"
    echo -e "${BLUE}所有分支:${NC}"
    echo "$all_branches"
    
    # 修复分支问题
    if [ -z "$current_branch" ] || [ "$current_branch" != "main" ]; then
        echo -e "${YELLOW}🔧 修复分支问题...${NC}"
        
        # 如果有main分支，切换到main
        if git show-ref --verify --quiet refs/heads/main; then
            echo -e "切换到已存在的main分支..."
            git checkout main
        else
            # 如果没有main分支，创建并切换
            echo -e "创建新的main分支..."
            git checkout -b main
        fi
    fi
    
    # 检查远程仓库配置
    echo -e "${YELLOW}🔗 检查远程仓库配置...${NC}"
    
    if git remote get-url origin >/dev/null 2>&1; then
        local remote_url=$(git remote get-url origin)
        echo -e "${BLUE}当前远程URL: ${remote_url}${NC}"
        
        # 检查URL格式是否正确
        if [[ $remote_url != git@github.com:* ]] && [[ $remote_url != https://github.com/* ]]; then
            echo -e "${YELLOW}⚠️  远程URL格式不正确，正在修复...${NC}"
            git remote set-url origin "git@github.com:${GITHUB_OWNER}/${repo_name}.git"
            echo -e "${GREEN}✅ 远程URL已修复${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  远程仓库未配置，正在添加...${NC}"
        git remote add origin "git@github.com:${GITHUB_OWNER}/${repo_name}.git"
        echo -e "${GREEN}✅ 远程仓库已添加${NC}"
    fi
    
    # 检查是否有文件需要提交
    echo -e "${YELLOW}📝 检查待提交文件...${NC}"
    
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}发现未提交的文件，正在提交...${NC}"
        git add .
        git commit -m "🔧 修复: 解决推送问题并完善项目配置

✨ 主要修复:
- 修复分支配置问题
- 更新远程仓库连接
- 确保所有文件正确提交

📦 项目状态: 已修复推送问题，ready for deployment

🤖 Auto-fixed with Claude Code"
        echo -e "${GREEN}✅ 文件已提交${NC}"
    else
        echo -e "${BLUE}ℹ️  没有待提交的文件${NC}"
    fi
    
    # 尝试推送
    echo -e "${YELLOW}🚀 尝试推送到GitHub...${NC}"
    
    # 方法1: 普通推送
    if git push -u origin main 2>/dev/null; then
        echo -e "${GREEN}✅ 推送成功 (方法1: 普通推送)${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  普通推送失败，尝试其他方法...${NC}"
    
    # 方法2: 获取远程分支信息并推送
    echo -e "${YELLOW}📡 获取远程仓库信息...${NC}"
    if git fetch origin 2>/dev/null; then
        echo -e "${GREEN}✅ 远程信息获取成功${NC}"
        
        # 检查远程是否有main分支
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            echo -e "${YELLOW}🔀 远程已有main分支，尝试合并推送...${NC}"
            git pull --allow-unrelated-histories origin main || true
            git push origin main
        else
            echo -e "${YELLOW}🆕 远程没有main分支，创建新分支...${NC}"
            git push -u origin main
        fi
    else
        # 方法3: 强制推送 (最后的选择)
        echo -e "${YELLOW}⚠️  获取远程信息失败，尝试强制推送...${NC}"
        echo -e "${RED}注意: 这将覆盖远程仓库的内容${NC}"
        read -p "确认强制推送？(y/N): " confirm_force
        
        if [[ $confirm_force =~ ^[Yy]$ ]]; then
            if git push -f -u origin main; then
                echo -e "${GREEN}✅ 强制推送成功${NC}"
                return 0
            else
                echo -e "${RED}❌ 强制推送也失败了${NC}"
                return 1
            fi
        else
            echo -e "${BLUE}ℹ️  跳过强制推送${NC}"
            return 1
        fi
    fi
}

# 诊断和修复所有问题
diagnose_and_fix() {
    echo -e "${YELLOW}🔍 开始诊断推送问题...${NC}"
    echo ""
    
    # 检查SSH连接
    echo -e "${YELLOW}🔐 检查SSH连接...${NC}"
    if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ SSH连接正常${NC}"
    else
        echo -e "${RED}❌ SSH连接失败${NC}"
        echo -e "${BLUE}💡 请检查SSH密钥配置${NC}"
        echo -e "   运行: ssh -T git@github.com"
        echo -e "   或执行: ./setup-ssh.sh"
        return 1
    fi
    
    # 检查GitHub CLI
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        echo -e "${GREEN}✅ GitHub CLI已配置${NC}"
        
        # 检查仓库是否存在
        echo -e "${YELLOW}🔍 检查远程仓库状态...${NC}"
        if gh repo view "${GITHUB_OWNER}/${FAILED_REPO}" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 远程仓库存在${NC}"
        else
            echo -e "${YELLOW}⚠️  远程仓库不存在，正在创建...${NC}"
            if gh repo create "${GITHUB_OWNER}/${FAILED_REPO}" --private --description "宠物管理系统共享组件库"; then
                echo -e "${GREEN}✅ 远程仓库创建成功${NC}"
            else
                echo -e "${RED}❌ 远程仓库创建失败${NC}"
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  GitHub CLI未配置，跳过仓库检查${NC}"
    fi
    
    echo ""
    
    # 修复指定仓库
    if fix_repo_push "$FAILED_REPO"; then
        echo -e "${GREEN}🎉 ${FAILED_REPO} 修复成功！${NC}"
    else
        echo -e "${RED}❌ ${FAILED_REPO} 修复失败${NC}"
        show_manual_steps
        return 1
    fi
}

# 显示手动修复步骤
show_manual_steps() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                     📋 手动修复步骤                              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}如果自动修复失败，请尝试以下手动步骤:${NC}"
    echo ""
    
    echo -e "${BLUE}1. 进入问题仓库:${NC}"
    echo -e "   cd ${BASE_PATH}/${FAILED_REPO}"
    echo ""
    
    echo -e "${BLUE}2. 检查Git状态:${NC}"
    echo -e "   git status"
    echo -e "   git branch -a"
    echo -e "   git remote -v"
    echo ""
    
    echo -e "${BLUE}3. 修复分支问题:${NC}"
    echo -e "   git checkout -b main  # 如果没有main分支"
    echo -e "   git add ."
    echo -e "   git commit -m '🔧 修复推送问题'"
    echo ""
    
    echo -e "${BLUE}4. 修复远程配置:${NC}"
    echo -e "   git remote set-url origin git@github.com:${GITHUB_OWNER}/${FAILED_REPO}.git"
    echo ""
    
    echo -e "${BLUE}5. 尝试推送:${NC}"
    echo -e "   git push -u origin main"
    echo -e "   # 如果失败，尝试:"
    echo -e "   git push -f -u origin main"
    echo ""
    
    echo -e "${BLUE}6. 验证推送结果:${NC}"
    echo -e "   访问: https://github.com/${GITHUB_OWNER}/${FAILED_REPO}"
    echo ""
}

# 批量修复所有仓库
fix_all_repos() {
    local repos=("pet-backend" "pet-frontend" "pet-mobile" "pet-customer-portal" "pet-shared")
    
    echo -e "${YELLOW}🔧 批量检查和修复所有仓库...${NC}"
    echo ""
    
    local success_count=0
    
    for repo in "${repos[@]}"; do
        echo -e "${BLUE}检查仓库: ${repo}${NC}"
        
        if fix_repo_push "$repo"; then
            echo -e "${GREEN}✅ ${repo} 正常${NC}"
            ((success_count++))
        else
            echo -e "${RED}❌ ${repo} 需要手动处理${NC}"
        fi
        echo ""
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 修复结果: ${success_count}/${#repos[@]} 个仓库成功${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 主函数
main() {
    echo -e "${YELLOW}🎯 针对 pet-shared 仓库的推送问题进行修复...${NC}"
    echo ""
    
    # 检查配置
    if [ -z "$GITHUB_OWNER" ]; then
        echo -e "${YELLOW}📝 请输入GitHub组织或用户名: ${NC}"
        read -p "> " GITHUB_OWNER
    fi
    
    diagnose_and_fix
}

# 脚本参数处理
case "${1:-}" in
    "--help"|"-h")
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help, -h      显示帮助信息"
        echo "  --all, -a       修复所有仓库"
        echo "  --repo REPO     修复指定仓库"
        echo ""
        echo "示例:"
        echo "  $0              # 修复pet-shared仓库"
        echo "  $0 --all        # 检查修复所有仓库"
        echo "  $0 --repo pet-backend  # 修复指定仓库"
        ;;
    "--all"|"-a")
        fix_all_repos
        ;;
    "--repo")
        if [ -n "$2" ]; then
            FAILED_REPO="$2"
            main
        else
            echo -e "${RED}❌ 请指定仓库名称${NC}"
            exit 1
        fi
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