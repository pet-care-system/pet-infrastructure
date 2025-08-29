#!/bin/bash

# GitHub SSH 配置脚本
# 用途：自动配置GitHub SSH连接

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                   🔐 GitHub SSH 配置向导                         ║"
echo "║                     一键配置SSH密钥和连接                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查现有SSH密钥
check_existing_keys() {
    echo -e "${YELLOW}🔍 检查现有SSH密钥...${NC}"
    
    if [ -f ~/.ssh/id_ed25519 ]; then
        echo -e "${GREEN}✅ 找到Ed25519密钥: ~/.ssh/id_ed25519${NC}"
        KEY_TYPE="ed25519"
        KEY_PATH="~/.ssh/id_ed25519"
        return 0
    elif [ -f ~/.ssh/id_rsa ]; then
        echo -e "${GREEN}✅ 找到RSA密钥: ~/.ssh/id_rsa${NC}"
        KEY_TYPE="rsa"
        KEY_PATH="~/.ssh/id_rsa"
        return 0
    elif [ -f ~/.ssh/id_ecdsa ]; then
        echo -e "${GREEN}✅ 找到ECDSA密钥: ~/.ssh/id_ecdsa${NC}"
        KEY_TYPE="ecdsa"
        KEY_PATH="~/.ssh/id_ecdsa"
        return 0
    else
        echo -e "${YELLOW}⚠️  未找到SSH密钥，需要生成新密钥${NC}"
        return 1
    fi
}

# 生成SSH密钥
generate_ssh_key() {
    echo -e "${YELLOW}🔑 生成SSH密钥...${NC}"
    
    # 获取用户邮箱
    echo -e "${BLUE}📧 请输入你的GitHub邮箱地址:${NC}"
    read -p "> " email
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ 邮箱地址不能为空${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔒 选择密钥类型:${NC}"
    echo "1) Ed25519 (推荐 - 更安全、更快)"
    echo "2) RSA (兼容性更好)"
    read -p "请选择 (1-2): " key_choice
    
    case $key_choice in
        1)
            echo -e "${YELLOW}生成Ed25519密钥...${NC}"
            ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519
            KEY_TYPE="ed25519"
            KEY_PATH="~/.ssh/id_ed25519"
            ;;
        2)
            echo -e "${YELLOW}生成RSA密钥...${NC}"
            ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa
            KEY_TYPE="rsa"
            KEY_PATH="~/.ssh/id_rsa"
            ;;
        *)
            echo -e "${RED}❌ 无效选择，默认使用Ed25519${NC}"
            ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519
            KEY_TYPE="ed25519"
            KEY_PATH="~/.ssh/id_ed25519"
            ;;
    esac
    
    echo -e "${GREEN}✅ SSH密钥生成完成${NC}"
}

# 启动SSH agent并添加密钥
setup_ssh_agent() {
    echo -e "${YELLOW}🔧 配置SSH agent...${NC}"
    
    # 检查SSH agent是否运行
    if ! pgrep -x ssh-agent > /dev/null; then
        echo -e "启动SSH agent..."
        eval "$(ssh-agent -s)"
    else
        echo -e "${GREEN}✅ SSH agent已运行${NC}"
    fi
    
    # 添加密钥到agent
    case $KEY_TYPE in
        "ed25519")
            ssh-add ~/.ssh/id_ed25519
            ;;
        "rsa")
            ssh-add ~/.ssh/id_rsa
            ;;
        "ecdsa")
            ssh-add ~/.ssh/id_ecdsa
            ;;
    esac
    
    echo -e "${GREEN}✅ SSH密钥已添加到agent${NC}"
}

# 创建SSH配置文件
create_ssh_config() {
    echo -e "${YELLOW}📝 创建SSH配置文件...${NC}"
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # 检查配置文件是否存在
    if [ -f ~/.ssh/config ]; then
        echo -e "${YELLOW}⚠️  SSH配置文件已存在${NC}"
        read -p "是否备份现有配置并创建新配置？(y/N): " backup_config
        
        if [[ $backup_config =~ ^[Yy]$ ]]; then
            cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
            echo -e "${GREEN}✅ 现有配置已备份${NC}"
        else
            echo -e "${BLUE}ℹ️  跳过配置文件创建${NC}"
            return 0
        fi
    fi
    
    # 创建优化的SSH配置
    cat > ~/.ssh/config << EOF
# GitHub.com
Host github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_${KEY_TYPE}
  UseKeychain yes
  AddKeysToAgent yes
  
# 如果企业网络阻止SSH端口22，取消注释下面的配置
# Host github.com
#   Hostname ssh.github.com
#   Port 443
#   User git

EOF

    chmod 600 ~/.ssh/config
    echo -e "${GREEN}✅ SSH配置文件已创建${NC}"
}

# 复制公钥到剪贴板
copy_public_key() {
    echo -e "${YELLOW}📋 复制公钥到剪贴板...${NC}"
    
    local pub_key_file=""
    case $KEY_TYPE in
        "ed25519")
            pub_key_file="~/.ssh/id_ed25519.pub"
            ;;
        "rsa")
            pub_key_file="~/.ssh/id_rsa.pub"
            ;;
        "ecdsa")
            pub_key_file="~/.ssh/id_ecdsa.pub"
            ;;
    esac
    
    # 根据操作系统复制到剪贴板
    if command -v pbcopy >/dev/null; then
        # macOS
        eval "pbcopy < $pub_key_file"
        echo -e "${GREEN}✅ 公钥已复制到剪贴板 (macOS)${NC}"
    elif command -v xclip >/dev/null; then
        # Linux with xclip
        eval "xclip -selection clipboard < $pub_key_file"
        echo -e "${GREEN}✅ 公钥已复制到剪贴板 (Linux)${NC}"
    elif command -v xsel >/dev/null; then
        # Linux with xsel
        eval "xsel --clipboard --input < $pub_key_file"
        echo -e "${GREEN}✅ 公钥已复制到剪贴板 (Linux)${NC}"
    elif command -v clip >/dev/null; then
        # Windows (Git Bash)
        eval "clip < $pub_key_file"
        echo -e "${GREEN}✅ 公钥已复制到剪贴板 (Windows)${NC}"
    else
        echo -e "${YELLOW}⚠️  无法自动复制到剪贴板，请手动复制：${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        eval "cat $pub_key_file"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

# 指导添加公钥到GitHub
guide_github_setup() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    📝 添加SSH密钥到GitHub                        ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}📋 请按以下步骤操作：${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} 打开GitHub SSH设置页面："
    echo -e "   ${BLUE}https://github.com/settings/ssh/new${NC}"
    echo ""
    echo -e "${BLUE}2.${NC} 填写SSH密钥信息："
    echo -e "   • ${YELLOW}Title${NC}: 描述性名称 (如: MacBook Pro - Pet Project)"
    echo -e "   • ${YELLOW}Key Type${NC}: Authentication Key"
    echo -e "   • ${YELLOW}Key${NC}: 粘贴剪贴板中的公钥内容"
    echo ""
    echo -e "${BLUE}3.${NC} 点击 ${GREEN}Add SSH key${NC} 按钮"
    echo ""
    echo -e "${BLUE}4.${NC} 确认GitHub密码"
    echo ""
    
    read -p "按Enter键继续测试SSH连接..."
}

# 测试SSH连接
test_ssh_connection() {
    echo -e "${YELLOW}🔍 测试GitHub SSH连接...${NC}"
    
    echo -e "${BLUE}正在连接到GitHub...${NC}"
    
    # 测试连接，捕获输出
    ssh_output=$(ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1)
    ssh_exit_code=$?
    
    if echo "$ssh_output" | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ GitHub SSH连接成功！${NC}"
        
        # 提取用户名
        username=$(echo "$ssh_output" | grep -o "Hi [^!]*" | cut -d' ' -f2)
        if [ -n "$username" ]; then
            echo -e "${BLUE}🎉 GitHub用户: ${username}${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ SSH连接失败${NC}"
        echo -e "${YELLOW}输出信息:${NC}"
        echo "$ssh_output"
        echo ""
        echo -e "${BLUE}💡 请检查：${NC}"
        echo -e "   • SSH密钥是否已添加到GitHub"
        echo -e "   • 密钥权限是否正确"
        echo -e "   • 网络连接是否正常"
        echo ""
        
        return 1
    fi
}

# 显示完成信息
show_completion() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 SSH配置完成！                             ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}🔑 SSH密钥信息:${NC}"
    echo -e "   • 类型: ${KEY_TYPE^^}"
    echo -e "   • 路径: ${KEY_PATH}"
    echo -e "   • 配置: ~/.ssh/config"
    echo ""
    
    echo -e "${YELLOW}🚀 下一步操作:${NC}"
    echo -e "${BLUE}1.${NC} 现在可以运行GitHub同步脚本："
    echo -e "   ${GREEN}./github-setup.sh${NC}"
    echo ""
    echo -e "${BLUE}2.${NC} 使用SSH方式克隆仓库："
    echo -e "   ${GREEN}git clone git@github.com:username/repository.git${NC}"
    echo ""
    echo -e "${BLUE}3.${NC} 修改现有仓库为SSH方式："
    echo -e "   ${GREEN}git remote set-url origin git@github.com:username/repository.git${NC}"
    echo ""
    
    echo -e "${GREEN}✨ GitHub SSH配置已完成，可以安全便捷地管理代码了！${NC}"
}

# 主函数
main() {
    if check_existing_keys; then
        echo -e "${BLUE}是否使用现有密钥？(Y/n): ${NC}"
        read -p "> " use_existing
        
        if [[ $use_existing =~ ^[Nn]$ ]]; then
            generate_ssh_key
        fi
    else
        generate_ssh_key
    fi
    
    setup_ssh_agent
    create_ssh_config
    copy_public_key
    guide_github_setup
    
    if test_ssh_connection; then
        show_completion
    else
        echo -e "${YELLOW}⚠️  SSH连接测试失败，请检查配置后重试${NC}"
        echo -e "${BLUE}💡 可以稍后运行 'ssh -T git@github.com' 再次测试${NC}"
    fi
}

# 脚本参数处理
case "${1:-}" in
    "--help"|"-h")
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help, -h      显示帮助信息"
        echo "  --test, -t      仅测试SSH连接"
        echo "  --config, -c    仅创建SSH配置文件"
        echo ""
        echo "示例:"
        echo "  $0              # 执行完整SSH配置"
        echo "  $0 --test       # 测试现有SSH连接"
        ;;
    "--test"|"-t")
        if check_existing_keys; then
            test_ssh_connection
        else
            echo -e "${RED}❌ 未找到SSH密钥，请先运行完整配置${NC}"
            exit 1
        fi
        ;;
    "--config"|"-c")
        if check_existing_keys; then
            create_ssh_config
        else
            echo -e "${RED}❌ 未找到SSH密钥，请先生成密钥${NC}"
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