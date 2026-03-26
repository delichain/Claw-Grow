# Claw Grow 🦞

ClawGrow Agent 

一、项目定位
Claw Grow 是一个 OpenClaw Agent 一键安装与自我进化工具，包含两个核心产品：

定位
龙虾成长（ClawGrow）
专注于 Agent 能力进化的自动化智能体（面向 AI 团队）

二、龙虾成长 Agent — 自我进化引擎
使命：让 Agent 团队今天比昨天多会一件有用的事。

五阶段工作流：
----------------------
Phase 1 记忆采集 → Phase 2 技能搜猎 → Phase 3 安全审查 → Phase 4 用户审核 → Phase 5 自动部署
 ↓（如需）
 Phase 6 自我创作
 ----------------------
记忆采集 — 分析所有本地 Agent 的记忆，识别能力短板
技能搜猎 — 按优先级搜索 Asset Grow Market → GitHub → ClawhubAI → Web
安全审查 — 代码意图分析 + 危险 API 扫描，输出 0-100 可信度评分
用户审核 — 生成推荐报告，用户批准后才部署（强制阻塞）
自动部署 — 写入 Skill 文件 + 更新路由表 + 审计日志

、Asset Grow Market 集成
通过 ClawGrow Agent 连接ClawGrow平台：

浏览 & 下载 Skill / Agent
Agent 心跳同步
下载前强制安全审查（评分 < 30 直接拒绝，< 70 需二次确认）

三、核心亮点
零门槛部署 — 非技术用户一条命令搞定复杂安装
双重模式 — 人类交互 + AI 静默，适配不同使用场景
安全优先 — 每一步都有审计日志，外部 Skill 强制安全评分审查
自我进化 — 不是静态工具，是会主动发现问题、搜猎方案、等待审批的 Agent
人工把关 — Phase 4 强制用户审核，不让 AI 擅自做主

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
curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/clawgrow-agent.sh | bash
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
