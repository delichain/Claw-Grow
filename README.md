# Claw-Grow 🦞

OpenClaw Agent 一键安装脚本，支持交互式和静默模式安装。开箱即用，自带技能工具箱。

## 功能特性

- ✅ 交互式安装向导
- ✅ 41+ 模型选择（Anthropic、OpenAI、MiniMax、Moonshot 等）
- ✅ 支持飞书、Telegram、Discord 等多通道配置
- ✅ **内置 8 大技能工具箱**（搜索、安装、协作、创造）
- ✅ 自动复制 API 配置
- ✅ 安全检查（不包含任何 API Key）

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install-agent.sh | bash
```

## 内置技能

安装后的 Agent 默认拥有以下技能：

| 类别 | 技能 |
|------|------|
| 🔍 搜索发现 | web_search, tavily, find-skills |
| 📦 获取安装 | github, clawhub |
| 🤝 协作执行 | agent-reach |
| 🧠 创造进化 | skill-creator, self-improvement |

详细说明见 [TOOLS.md](./TOOLS.md)

## 静默模式

```bash
# 通过环境变量
AGENT_ID=myagent AGENT_NAME="My Agent" curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install-agent.sh | bash

# 或使用 -y 参数
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install-agent.sh | bash -s -- -y
```

## 使用方式

### 1. 交互模式

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install-agent.sh | bash
```

脚本会一步步提示：
1. 输入 Agent ID
2. 输入显示名称
3. 选择 Emoji
4. 选择模型 (1-41)
5. 选择工具配置
6. 选择通道配置

### 2. 卸载 Agent

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install-agent.sh | bash -s -- --uninstall <agent-id>
```

### 3. 查看状态

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install-agent.sh | bash -s -- --status
```

## 支持的模型

| 类别 | 模型数 |
|------|-------|
| Anthropic | 3 |
| OpenAI | 4 |
| MiniMax | 4 |
| Moonshot | 3 |
| HuggingFace | 3 |
| Venice AI | 4 |
| Together AI | 3 |
| OpenRouter | 3 |
| Mistral | 2 |
| NVIDIA | 2 |
| Z.AI | 2 |
| Xiaomi MiMo | 1 |
| Ollama | 4 |
| 其他 | 2 |

## 注意事项

- 安装前请确保已安装 `openclaw` 和 `jq`
- 脚本会自动从已有 Agent 复制 API 配置
- 不会包含任何用户 API Key 或个人信息

## 本地开发

```bash
# 克隆仓库
git clone https://github.com/delichain/Claw-Grow.git
cd Claw-Grow

# 本地测试
chmod +x install-agent.sh
./install-agent.sh
```

## License

MIT
