# 🔐 GitHub SSH 配置指南

## 为什么使用SSH？

- ✅ **更安全**: 不需要在URL中暴露用户名
- ✅ **更方便**: 不需要每次输入密码
- ✅ **更快速**: SSH连接速度更快
- ✅ **企业级**: 大多数企业都使用SSH方式

## 📋 SSH配置步骤

### 步骤1: 检查现有SSH密钥

```bash
# 检查是否已有SSH密钥
ls -al ~/.ssh

# 查找以下文件之一：
# - id_rsa.pub (RSA密钥)
# - id_ed25519.pub (Ed25519密钥，推荐)
# - id_ecdsa.pub (ECDSA密钥)
```

### 步骤2: 生成新的SSH密钥 (如果没有)

#### 推荐: 生成Ed25519密钥 (更安全、更快)
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

#### 或者生成RSA密钥 (兼容性更好)
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

**交互式选项**:
- `Enter file in which to save the key`: 按回车使用默认路径
- `Enter passphrase`: 输入密码保护密钥 (推荐)
- `Enter same passphrase again`: 再次输入密码

### 步骤3: 启动SSH agent并添加密钥

```bash
# 启动ssh-agent
eval "$(ssh-agent -s)"

# 添加SSH密钥到agent (Ed25519)
ssh-add ~/.ssh/id_ed25519

# 或者添加RSA密钥
ssh-add ~/.ssh/id_rsa
```

### 步骤4: 复制公钥到剪贴板

#### macOS:
```bash
# Ed25519密钥
pbcopy < ~/.ssh/id_ed25519.pub

# 或RSA密钥
pbcopy < ~/.ssh/id_rsa.pub
```

#### Linux:
```bash
# Ed25519密钥
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard

# 或RSA密钥
cat ~/.ssh/id_rsa.pub | xclip -selection clipboard
```

#### Windows (Git Bash):
```bash
# Ed25519密钥
cat ~/.ssh/id_ed25519.pub | clip

# 或RSA密钥
cat ~/.ssh/id_rsa.pub | clip
```

### 步骤5: 添加SSH密钥到GitHub

1. 登录 [GitHub](https://github.com)
2. 点击右上角头像 → `Settings`
3. 左侧导航点击 `SSH and GPG keys`
4. 点击 `New SSH key`
5. 填写信息：
   - **Title**: 描述性名称 (如: "MacBook Pro - Pet Project")
   - **Key Type**: Authentication Key
   - **Key**: 粘贴刚才复制的公钥内容
6. 点击 `Add SSH key`
7. 确认GitHub密码

### 步骤6: 测试SSH连接

```bash
ssh -T git@github.com
```

**成功输出示例**:
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

**如果连接失败**, 请检查：
- SSH密钥是否正确添加到GitHub
- SSH agent是否运行
- 密钥文件权限是否正确

## 🔧 SSH配置文件优化 (可选)

创建或编辑 `~/.ssh/config` 文件：

```bash
# GitHub.com
Host github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_ed25519
  UseKeychain yes
  AddKeysToAgent yes
```

## 🚀 使用SSH URL进行Git操作

配置完成后，使用SSH URL进行Git操作：

```bash
# 克隆仓库
git clone git@github.com:username/repository.git

# 修改现有仓库的远程URL
git remote set-url origin git@github.com:username/repository.git

# 检查远程URL
git remote -v
```

## 🛠️ 自动化脚本更新

我已经更新了 `github-setup.sh` 脚本来使用SSH：

1. **自动检查SSH密钥**: 脚本会检查是否存在SSH密钥
2. **测试SSH连接**: 验证GitHub SSH连接是否正常
3. **使用SSH URL**: 所有Git操作都使用SSH URL

运行更新后的脚本：

```bash
cd /Users/newdroid/Documents/project
./github-setup.sh
```

## ❗ 常见问题解决

### 问题1: SSH连接被拒绝
```bash
# 详细调试SSH连接
ssh -vT git@github.com
```

**可能原因**:
- SSH密钥未添加到GitHub
- SSH agent未运行
- 防火墙阻止SSH连接

### 问题2: 权限被拒绝 (Permission denied)
```bash
# 检查SSH密钥权限
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh
```

### 问题3: 密钥不被识别
```bash
# 重新添加密钥到agent
ssh-add -D  # 删除所有密钥
ssh-add ~/.ssh/id_ed25519  # 重新添加密钥
```

### 问题4: 企业网络限制SSH
如果企业网络阻止SSH端口22，可以使用HTTPS端口443：

在 `~/.ssh/config` 中添加：
```
Host github.com
  Hostname ssh.github.com
  Port 443
  User git
```

## 🔒 安全最佳实践

1. **使用密码保护**: 为SSH密钥设置密码
2. **定期轮换**: 定期更新SSH密钥
3. **限制权限**: 确保密钥文件权限正确
4. **备份密钥**: 安全备份SSH密钥对
5. **监控使用**: 定期检查GitHub的SSH密钥使用记录

## ✅ 配置完成检查清单

- [ ] SSH密钥已生成
- [ ] 公钥已添加到GitHub
- [ ] SSH连接测试成功
- [ ] Git远程URL已更新为SSH格式
- [ ] 可以正常推送和拉取代码

配置完成后，你就可以使用SSH方式安全便捷地管理GitHub仓库了！🎉

---
📖 更多信息: [GitHub SSH文档](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)