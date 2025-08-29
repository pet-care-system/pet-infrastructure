# 🏢 GitHub组织管理快速指南

## 🚀 三种使用方式

### 方式一: 直接在组织中创建新仓库 (推荐)

```bash
cd /Users/newdroid/Documents/project

# 使用组织模式推送（脚本会询问是否使用组织）
./github-setup.sh
```

脚本会询问：
- 你的GitHub用户名
- 是否使用组织模式
- 组织名称
- 自动在组织中创建所有仓库

### 方式二: 迁移现有个人仓库到组织

如果你已经有个人仓库，想迁移到组织：

```bash
# 迁移现有仓库到组织
./migrate-to-org.sh
```

脚本会自动：
- 检查现有仓库
- 验证组织权限
- 执行仓库转移
- 更新本地远程URL

### 方式三: 手动创建组织后使用

1. 先在GitHub创建组织
2. 运行脚本时选择组织模式
3. 输入组织名称即可

## 🏗️ 组织优势对比

| 特性 | 个人账户 | GitHub组织 |
|------|----------|------------|
| **品牌形象** | 个人项目 | 🏢 专业企业形象 |
| **团队协作** | 基础协作 | 👥 高级团队管理 |
| **权限控制** | 简单权限 | 🔐 细粒度权限控制 |
| **Secrets管理** | 每个仓库单独配置 | 📦 组织级共享配置 |
| **扩展性** | 有限 | 🚀 支持大型团队 |
| **费用** | 个人承担 | 💼 企业级计费 |

## 📋 推荐的组织结构

```
pet-care-system (组织)
├── 📊 Repositories
│   ├── pet-backend
│   ├── pet-frontend  
│   ├── pet-mobile
│   ├── pet-customer-portal
│   ├── pet-shared
│   ├── .github (组织profile)
│   └── pet-docs (文档仓库)
├── 👥 Teams
│   ├── core-team (核心开发团队)
│   ├── mobile-team (移动端团队)
│   ├── product-team (产品团队)
│   └── external-contributors
└── ⚙️ Settings
    ├── Secrets (组织级密钥)
    ├── Actions (CI/CD设置)
    └── Security (安全策略)
```

## 🔧 组织设置步骤

### 1. 创建GitHub组织

**方式A: GitHub网页创建**
1. 访问 https://github.com/settings/organizations
2. 点击 "New organization"
3. 选择计划 (Free/Team/Enterprise)
4. 填写组织信息

**方式B: GitHub CLI创建**
```bash
gh api orgs -X POST -f login="pet-care-system" -f email="your-email@example.com"
```

### 2. 基础配置

```bash
# 设置组织信息
gh api orgs/pet-care-system -X PATCH \
  -f description="现代化宠物护理管理平台" \
  -f location="China" \
  -f email="contact@petcare.com"
```

### 3. 创建团队结构

```bash
# 创建核心团队
gh api orgs/pet-care-system/teams -X POST \
  -f name="core-team" \
  -f description="核心开发团队" \
  -f privacy="closed"

# 创建移动端团队  
gh api orgs/pet-care-system/teams -X POST \
  -f name="mobile-team" \
  -f description="移动端开发团队" \
  -f privacy="closed"
```

## 🎯 使用场景对比

### 个人开发者 → 推荐个人账户
- 学习项目
- 个人作品集
- 小型实验项目
- 预算有限

### 小团队 (2-5人) → 推荐组织Free计划
- 团队协作项目
- 开源项目维护
- 初创公司产品
- 需要专业形象

### 中型团队 (5-20人) → 推荐组织Team计划
- 商业产品开发
- 多项目管理
- 需要高级权限控制
- 企业级安全需求

### 大型企业 (20+人) → 推荐Enterprise计划
- 企业级产品开发
- 复杂的权限管理
- 合规性要求
- 24/7技术支持

## 💰 成本分析

### GitHub组织计费模式

| 计划 | 价格 | 适用场景 | 主要限制 |
|------|------|----------|----------|
| **Free** | $0 | 个人/小团队 | 3000分钟Actions |
| **Team** | $4/用户/月 | 中小团队 | 高级功能 |
| **Enterprise** | $21/用户/月 | 大型企业 | 全功能 |

### 成本优化建议

1. **从Free开始** - 验证组织模式价值
2. **按需升级** - 根据功能需求和团队规模
3. **合理使用Actions** - 自托管Runners节省成本
4. **定期审查** - 清理不活跃成员和仓库

## 🔐 安全配置清单

### 组织安全设置

```bash
# 启用两步验证要求
gh api orgs/pet-care-system -X PATCH \
  -f two_factor_requirement_enabled=true

# 设置成员权限
gh api orgs/pet-care-system -X PATCH \
  -f members_can_create_repositories=false \
  -f default_repository_permission="read"
```

### 必备安全配置

- [ ] 强制两步验证 (2FA)
- [ ] 限制仓库创建权限
- [ ] 启用Secret Scanning
- [ ] 配置Dependabot
- [ ] 设置IP允许列表 (如需要)
- [ ] 启用审计日志
- [ ] 配置分支保护规则

## 🎨 组织定制

### 创建组织Profile

1. 创建特殊仓库 `.github`
2. 添加 `profile/README.md`：

```markdown
# 🐾 Pet Care Management System

> 现代化宠物护理管理平台

## 🚀 产品矩阵

- 🔙 **Backend API** - 核心业务服务
- 🖥️ **Web Portal** - 管理员界面
- 📱 **Mobile App** - 客户端应用
- 👥 **Customer Portal** - 客户服务门户

## 🤝 加入我们

查看 [贡献指南](CONTRIBUTING.md) 了解如何参与开发。
```

### 设置组织头像和信息

- 上传专业的组织头像
- 设置组织网站和联系方式
- 配置组织描述和位置信息

## 📊 监控和分析

### 组织Insights

组织提供强大的分析功能：

```bash
# 查看组织活动统计
gh api orgs/pet-care-system/stats/contributors

# 查看仓库流量统计  
gh api repos/pet-care-system/pet-backend/traffic/views

# 查看依赖关系
gh api orgs/pet-care-system/dependency-graph/compare
```

### 推荐监控指标

- **开发活跃度** - 提交频率、PR数量
- **代码质量** - 测试覆盖率、代码审查
- **安全状况** - 漏洞数量、依赖更新
- **团队协作** - 成员活跃度、权限使用

## 🎉 组织最佳实践

### 命名规范

```
组织: pet-care-system
仓库: pet-backend, pet-frontend, pet-mobile
团队: core-team, mobile-team, product-team
分支: main, develop, feature/*, hotfix/*
```

### 工作流程

1. **功能开发** - Feature分支 → PR → 代码审查 → 合并
2. **发布管理** - 语义化版本 → 自动发布 → 部署
3. **问题跟踪** - Issues → 项目看板 → 里程碑
4. **文档维护** - README → Wiki → 代码注释

### 团队协作

- **代码审查** - 所有PR必须经过审查
- **自动化测试** - 确保代码质量
- **定期会议** - 团队同步和技术分享
- **知识分享** - 文档和最佳实践

## 🚀 立即开始

### 选择最适合的方式：

**新项目 → 直接使用组织**
```bash
./github-setup.sh  # 选择组织模式
```

**现有项目 → 迁移到组织**  
```bash
./migrate-to-org.sh  # 自动迁移
```

**配置组织Secrets**
```bash
./setup-secrets.sh  # 选择组织模式
```

## 💡 进阶技巧

### 组织自动化

```bash
# 批量添加团队成员
for user in alice bob charlie; do
    gh api orgs/pet-care-system/teams/core-team/memberships/$user \
        -X PUT -f role="member"
done

# 批量设置仓库权限
for repo in pet-backend pet-frontend pet-mobile; do
    gh api orgs/pet-care-system/teams/core-team/repos/pet-care-system/$repo \
        -X PUT -f permission="admin"
done
```

### 高级权限管理

- **CODEOWNERS文件** - 自动分配代码审查者
- **分支保护规则** - 防止直接推送到主分支  
- **状态检查** - CI/CD必须通过才能合并
- **自动合并** - 满足条件时自动合并PR

组织模式将为你的宠物管理系统项目带来专业性和扩展性！🎊

---

📖 详细文档: [ORGANIZATION_SETUP_GUIDE.md](ORGANIZATION_SETUP_GUIDE.md)
🔄 迁移工具: [migrate-to-org.sh](migrate-to-org.sh)