# Claw Grow 🦞

OpenClaw Agent 一键安装向导

## 功能

- ✅ 交互式 Agent 安装向导
- ✅ 支持多种模型（MiniMax、OpenAI、Anthropic、Moonshot、DeepSeek、Google、Ollama）
- ✅ 支持多种通道（飞书、Telegram、Discord、Slack、WhatsApp、Signal、LINE）
- ✅ 自动从 GitHub 下载并部署身份文件和 Skills
- ✅ 静默模式支持（环境变量）
- ✅ 支持 Agent 模式（输出结构化清单供其他 Agent 调用）

## 快速开始

### 交互模式

```bash
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash
```

### 静默模式

使用空格分隔变量（确保变量能传递到子进程）：

```bash
AGENT_NAME="我的Agent" AGENT_EMOJI="🦞" MODEL="minimax/MiniMax-M2.5" CHANNEL_TYPE="telegram" TELEGRAM_TOKEN="xxx" bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
```

飞书示例：
```bash
AGENT_NAME="我的Agent" AGENT_EMOJI="🦞" MODEL="minimax/MiniMax-M2.5" CHANNEL_TYPE="feishu" FEISHU_ACCOUNT="myagent" FEISHU_APP_ID="cli_xxx" FEISHU_APP_SECRET="xxx" bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
```

Discord 示例：
```bash
AGENT_NAME="我的Agent" AGENT_EMOJI="🤖" MODEL="anthropic/claude-sonnet-4-6" CHANNEL_TYPE="discord" DISCORD_TOKEN="xxx" bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
```

Slack 示例：
```bash
AGENT_NAME="我的Agent" AGENT_EMOJI="💼" MODEL="openai/gpt-5.4" CHANNEL_TYPE="slack" SLACK_TOKEN="xoxb-xxx" bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
```

跳过通道配置：
```bash
AGENT_NAME="我的Agent" AGENT_EMOJI="🦞" MODEL="minimax/MiniMax-M2.5" CHANNEL_TYPE="skip" bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
```

## 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| AGENT_ID | Agent ID | clawgrow |
| AGENT_NAME | 显示名称 | 龙虾成长 |
| AGENT_EMOJI | Emoji | 🦞 |
| MODEL | 模型 ID（必需） | - |
| CHANNEL_TYPE | 通道类型（必需） | - |
| DEPLOY_FROM_GITHUB | 是否从 GitHub 部署配置和 Skills | true |

### 通道配置

| 通道 | 必需变量 | 说明 |
|------|----------|------|
| feishu | FEISHU_ACCOUNT, FEISHU_APP_ID, FEISHU_APP_SECRET | 飞书 Bot |
| telegram | TELEGRAM_TOKEN | Telegram Bot Token |
| discord | DISCORD_TOKEN | Discord Bot Token |
| slack | SLACK_TOKEN | Slack Bot Token |
| whatsapp | WHATSAPP_PHONE, WHATSAPP_TOKEN | WhatsApp Business |
| signal | SIGNAL_PHONE, SIGNAL_TOKEN | Signal |
| line | LINE_CHANNEL_ID, LINE_CHANNEL_SECRET, LINE_TOKEN | LINE Messaging API |
| skip | - | 不配置通道 |

### 支持的模型

| 编号 | 模型 ID |
|------|---------|
| 1 | minimax/MiniMax-M2.5 |
| 2 | minimax/MiniMax-M2.5-highspeed |
| 3 | anthropic/claude-sonnet-4-6 |
| 4 | openai/gpt-5.4 |
| 5 | moonshot/kimi-k2.5 |
| 6 | ollama/qwen2.5:14b |
| 7 | ollama/deepseek-r1:32b |
| 8 | custom |

## Agent 模式

当脚本检测到非交互模式时，会输出结构化清单供其他 Agent 调用：

```
CLAW_GROW_INSTALL_REQUIRED=true

请按以下步骤向用户收集信息：

步骤 1：基本信息
步骤 2：模型选择
步骤 3：通道选择
...
```

## GitHub 部署

默认会从 GitHub 下载身份文件和 Skills：

- AGENTS.md
- SOUL.md
- TOOLS.md
- USER.md
- skills/

## 版本

当前版本：2.3.0
