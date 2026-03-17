# Claw Grow 🦞

OpenClaw Agent 一键安装向导

## 功能

- ✅ 交互式 Agent 安装向导
- ✅ 支持多种模型（MiniMax、OpenAI、Anthropic、Moonshot）
- ✅ 支持多种通道（飞书、Telegram、Discord）
- ✅ 自动从 GitHub 下载并部署身份文件和 Skills
- ✅ 静默模式支持（环境变量）

## 快速开始

### 交互模式

```
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/clawgrow-agent.sh -o clawgrow-agent.sh
bash clawgrow-agent.sh
```

### 静默模式

```bash
AGENT_NAME="我的Agent" \
AGENT_EMOJI="🍌" \
MODEL="minimax/MiniMax-M2.5" \
CHANNEL_TYPE="feishu" \
FEISHU_ACCOUNT="myagent" \
FEISHU_APP_ID="cli_xxx" \
FEISHU_APP_SECRET="xxx" \
bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
```

## 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| AGENT_ID | Agent ID | clawgrow |
| AGENT_NAME | 显示名称 | 龙虾成长 |
| AGENT_EMOJI | Emoji | 🦞 |
| MODEL | 模型 ID | minimax/MiniMax-M2.5 |
| CHANNEL_TYPE | 通道类型 | feishu |
| FEISHU_ACCOUNT | 飞书账号名 | AGENT_ID |
| FEISHU_APP_ID | 飞书 App ID | - |
| FEISHU_APP_SECRET | 飞书 App Secret | - |

## GitHub 部署

默认会从 GitHub 下载身份文件和 Skills：

- AGENTS.md
- SOUL.md
- TOOLS.md
- USER.md
- skills/

## 版本

当前版本：2.3.0
