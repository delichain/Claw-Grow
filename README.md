# Claw-Grow 🦞

OpenClaw Agent 一键安装脚本，支持交互式和静默模式安装。开箱即用，自置技能工具箱。

## 两种安装模式

| 模式 | 命令 | 适用场景 |
|------|------|----------|
| 🤖 **Agent 部署** | 下载 [clawgrow-agent.sh](https://github.com/delichain/Claw-Grow/blob/main/clawgrow-agent.sh) 后运行 | Agent 自动部署 |
| 👤 **我是人类** | `curl ... | bash` | 在终端直接运行 |

## 一键安装

### 方式一：我是人类（终端交互）

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash
```

安装过程中会一步步提示选择：
1. 输入显示名称
2. 选择 Emoji
3. 选择模型
4. 选择通信通道 (飞书/Telegram/Discord/Slack 等)
5. 审核确认后执行安装

### 方式二：Agent 部署

下载 [clawgrow-agent.sh](https://github.com/delichain/Claw-Grow/blob/main/clawgrow-agent.sh) 文件后在 Agent 对话框中运行，脚本会自动引导用户完成配置。

```bash
# 下载并运行
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/clawgrow-agent.sh -o clawgrow-agent.sh
bash clawgrow-agent.sh
```

## 功能特性

- ✅ 交互式安装向导
- ✅ 模型选择（MiniMax、Anthropic、OpenAI、Moonshot 等）
- ✅ 通信通道支持（飞书、Telegram、Discord、Slack 等）
- ✅ 内置技能工具箱
- ✅ 自动复制 API 配置
- ✅ 安全检查（不包含任何 API Key）

## 支持的模型

| 类别 | 模型 |
|------|------|
| Anthropic | Claude Opus 4.6, Sonnet 4.6, Haiku 4.6 |
| OpenAI | GPT-5.4, GPT-5.4 Pro, O3, O3 Mini |
| MiniMax | M2.5, M2.5 高速版, M2.5 闪电版, VL-01 |
| Moonshot | Kimi K2.5, Kimi K2 Thinking, Kimi Coding |
| 开源 | DeepSeek R1, Qwen3 8B, Llama 3.3 70B |
| 本地 | Ollama Qwen2.5, Llama, DeepSeek R1 |

## 支持的通道

| 通道 | 状态 |
|------|------|
| 飞书 | ✅ 自动配置 |
| Telegram | ✅ 自动配置 |
| Discord | ✅ 自动配置 |
| Slack | ✅ 自动配置 |
| 跳过 | ✅ 稍后手动配置 |

## 高级用法

### 静默模式（自动确认）

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash -s -- -y
```

### 环境变量安装

```bash
AGENT_NAME="我的 Agent" MODEL="minimax/MiniMax-M2.5" curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash -s -- -y
```

### 卸载 Agent

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash -s -- --uninstall clawgrow
```

## 注意事项

- 安装前请确保已安装 `openclaw` 和 `jq`
- Agent ID 固定为 `clawgrow`
- 脚本会自动从已有 Agent 复制 API 配置
- 不会包含任何用户 API Key 或个人信息

## 本地开发

```bash
# 克隆仓库
git clone https://github.com/delichain/Claw-Grow.git
cd Claw-Grow

# 本地测试
chmod +x install.sh
./install.sh --help
```

## License

MIT
