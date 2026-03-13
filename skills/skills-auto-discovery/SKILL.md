# Skills 自动发现与安装

## 触发条件

当用户提到以下内容时激活：
- "自动发现 skills"
- "安装 skills 流程"
- "skills 工作流"
- "自动拉取 agent 记忆"

## 核心功能

### 步骤 1: 拉取并分析 Agent 记忆

```bash
# 拉取所有 agent 的记忆目录
AGENTS=("cherry" "pineapple" "main" "ponny")

for agent in "${AGENTS[@]}"; do
  memory_dir="~/.openclaw/workspace-$agent/memory/"
  if [[ -d "$memory_dir" ]]; then
    echo "=== $agent 的记忆 ==="
    ls -la "$memory_dir"
  fi
done
```

### 步骤 2: 搜索 Skills

优先使用 skillhub（国内），备选 clawhub（国际）：

```bash
# 先尝试 skillhub
skillhub search <关键词>

# 如果没有结果，尝试 clawhub
clawhub search <关键词>
```

### 步骤 3: 用户审核

将搜索结果格式化展示：
- 仓库名称
- Stars 数量
- 描述
- 安全风险评估

等待用户确认（yes/no）

### 步骤 4: 安装并记录

```bash
# 安装技能
clawhub install <仓库>

# 写入规则文档
echo "- **场景**: <描述>" >> ~/.openclaw/workspace-<agent>/AGENTS.md
```

## 安全检查

安装前必须检查：
1. 不包含用户 API keys
2. 不上传个人资料
3. 来源可信（高 stars + 官方推荐）

## 输出格式

```markdown
## 🔍 Skills 搜索结果

| 仓库 | Stars | 描述 | 风险 |
|------|-------|------|------|
| xxx | ⭐ 1.2k | xxx | 低 |

## ⚠️ 需要确认
- [ ] 安装 xxx skill？
```
