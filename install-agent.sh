#!/bin/bash
set -euo pipefail

# =============================================================================
# OpenClaw Agent Installer - 安全版
# =============================================================================
# Usage:
#   交互模式:    curl -fsSL <url> | bash
#   自动模式:    curl -fsSL <url> | bash -s -- -y
#   环境变量:    AGENT_ID=pine bash -s <<< ""
#   卸载:        curl -fsSL <url> | bash -s -- --uninstall
#   状态:        curl -fsSL <url> | bash -s -- --status
# =============================================================================

# ---------- 配置 ----------
readonly SCRIPT_VERSION="1.0.0"
readonly DEFAULT_MODEL="minimax-portal/MiniMax-M2.5"
readonly DEFAULT_TOOLS="minimal"

# ---------- 颜色 ----------
BOLD='\033[1m'
ACCENT='\033[38;2;255;77;77m'
SUCCESS='\033[38;2;0;229;204m'
ERROR='\033[38;2;230;57;70m'
WARN='\033[38;2;255;176;32m'
NC='\033[0m'

# ---------- 全局变量 ----------
FORCE=false
AUTO_MODE=false
DRY_RUN=false
OPERATION="install"

# Agent 相关变量初始化
AGENT_ID=""
AGENT_NAME=""
AGENT_EMOJI=""
MODEL=""
TOOLS_PROFILE=""
CHANNEL_TYPE=""
FEISHU_ACCOUNT=""
FEISHU_APP_ID=""
FEISHU_APP_SECRET=""
TELEGRAM_TOKEN=""
DISCORD_TOKEN=""
GROUP_ID=""
GROUP_MENTION=""

# ---------- 解析参数 ----------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_MODE=true ;;
            -f|--force) FORCE=true ;;
            --uninstall) OPERATION="uninstall" ;;
            --status) OPERATION="status" ;;
            --dry-run) DRY_RUN=true ;;
            -h|--help) show_help; exit 0 ;;
            *) echo -e "${ERROR}未知选项: $1${NC}"; show_help; exit 1 ;;
        esac
        shift
    done
}

show_help() {
    echo "OpenClaw Agent Installer v${SCRIPT_VERSION}"
    echo ""
    echo "用法: $(basename "$0") [选项]"
    echo ""
    echo "选项:"
    echo "  -y, --yes        自动确认所有提示"
    echo "  -f, --force      强制覆盖已存在的 Agent"
    echo "  --uninstall      卸载 Agent"
    echo "  --status         查看安装状态"
    echo "  --dry-run        模拟运行"
    echo "  -h, --help       显示帮助"
    echo ""
    echo "环境变量 (静默模式):"
    echo "  AGENT_ID         Agent ID (必需)"
    echo "  AGENT_NAME       显示名称"
    echo "  AGENT_EMOJI      Emoji"
    echo "  MODEL            模型"
    echo "  TOOLS_PROFILE    工具配置"
}

# ---------- 依赖检查 ----------
check_dependencies() {
    local missing=()

    if ! command -v openclaw &> /dev/null; then
        missing+=("openclaw")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${ERROR}缺少依赖: ${missing[*]}${NC}"
        echo "请先安装缺失的工具"
        exit 1
    fi
}

# ---------- 配置路径 ----------
init_paths() {
    OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
    BACKUP_FILE="$OPENCLAW_CONFIG.bak.$(date +%Y%m%d%H%M%S)"

    if [[ ! -f "$OPENCLAW_CONFIG" ]]; then
        echo -e "${ERROR}配置文件不存在: $OPENCLAW_CONFIG${NC}"
        exit 1
    fi
}

# ---------- 状态查询 ----------
cmd_status() {
    echo -e "${BOLD}📊 OpenClaw Agent 状态${NC}"
    echo ""

    local agents
    agents=$(jq -r '.agents.list[] | "\(.id)|\(.name)|\(.workspace)"' "$OPENCLAW_CONFIG" 2>/dev/null || echo "")

    if [[ -z "$agents" ]]; then
        echo "暂无已安装的 Agent"
        return
    fi

    printf "%-15s %-15s %s\n" "ID" "名称" "工作目录"
    echo "------------------------------------------------"
    while IFS='|' read -r id name workspace; do
        printf "%-15s %-15s %s\n" "$id" "$name" "$workspace"
    done <<< "$agents"
}

# ---------- 卸载 ----------
cmd_uninstall() {
    parse_uninstall_args "$@"

    if [[ -z "${AGENT_ID:-}" ]]; then
        echo -e "${ERROR}请指定要卸载的 Agent ID${NC}"
        echo "用法: $(basename "$0") --uninstall <agent-id>"
        exit 1
    fi

    AGENT_ID=$(echo "$AGENT_ID" | tr '[:upper:]' '[:lower:]')

    # 检查是否存在
    if ! jq --arg id "$AGENT_ID" '.agents.list[] | select(.id == $id)' "$OPENCLAW_CONFIG" > /dev/null 2>&1; then
        echo -e "${ERROR}Agent '$AGENT_ID' 不存在${NC}"
        exit 1
    fi

    # 获取工作目录（用于清理）
    local workspace
    workspace=$(jq --arg id "$AGENT_ID" -r '.agents.list[] | select(.id == $id) | .workspace' "$OPENCLAW_CONFIG")

    if [[ "$AUTO_MODE" != true ]]; then
        echo -e "${WARN}确定要卸载 Agent '$AGENT_ID' 吗？${NC}"
        echo "工作目录: $workspace"
        echo ""
        read -p "确认删除? [y/N] " -r
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            echo "已取消"
            exit 0
        fi
    fi

    echo -e "${BOLD}🗑️  卸载 Agent: $AGENT_ID${NC}"

    # 从列表中移除
    cp "$OPENCLAW_CONFIG" "$BACKUP_FILE"
    jq --arg id "$AGENT_ID" '.agents.list = [.agents.list[] | select(.id != $id)]' "$OPENCLAW_CONFIG" > "$OPENCLAW_CONFIG.tmp"
    mv "$OPENCLAW_CONFIG.tmp" "$OPENCLAW_CONFIG"

    # 清理工作目录
    if [[ -d "$workspace" ]]; then
        rm -rf "$workspace"
        echo "✓ 已删除工作目录: $workspace"
    fi

    # 重启 gateway
    if ! $DRY_RUN; then
        openclaw gateway restart 2>/dev/null || true
    fi

    echo -e "${SUCCESS}✓ Agent '$AGENT_ID' 已卸载${NC}"
}

parse_uninstall_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_MODE=true ;;
            -f|--force) FORCE=true ;;
            --dry-run) DRY_RUN=true ;;
            *) AGENT_ID="$1" ;;
        esac
        shift
    done
}

# ---------- 交互输入 ----------
prompt() {
    local prompt_text="$1"
    local default="$2"
    local var_name="$3"

    if [[ -n "${!var_name:-}" ]]; then
        return 0  # 环境变量已设置
    fi

    if [[ -n "$default" ]]; then
        read -p "$prompt_text [$default]: " -r
    else
        read -p "$prompt_text: " -r
    fi

    [[ -n "$REPLY" ]] && eval "$var_name=\$REPLY" || eval "$var_name=\$default"
}

prompt_secret() {
    local prompt_text="$1"
    local var_name="$2"

    echo -n "$prompt: "
    read -s -r
    echo
    [[ -n "$REPLY" ]] && eval "$var_name=\$REPLY"
}

prompt_yesno() {
    local prompt_text="$1"
    local default="$2"

    if [[ "$AUTO_MODE" == true ]]; then
        eval "$3=true"
        return
    fi

    local choices
    if [[ "$default" == "y" ]]; then
        choices="[Y/n]"
    else
        choices="[y/N]"
    fi

    read -p "$prompt_text $choices: " -r
    case "$REPLY" in
        y|Y) eval "$3=true" ;;
        n|N) eval "$3=false" ;;
        *) eval "$3=$default" ;;
    esac
}

prompt_choice() {
    local prompt_text="$1"
    shift
    local options=("$@")

    if [[ "$AUTO_MODE" == true ]]; then
        eval "$4=\${options[0]}"
        return
    fi

    local n=${#options[@]}
    echo "$prompt_text"
    for i in "${!options[@]}"; do
        echo "   [$((i+1))] ${options[$i]}"
    done

    while true; do
        read -p "   > " -r
        if [[ "$REPLY" =~ ^[1-9]$ ]] && [[ $REPLY -le $n ]]; then
            eval "$4=\${options[$((REPLY-1))]}"
            break
        fi
    done
}

# ---------- 安装主流程 ----------
cmd_install() {
    # 先检查 Agent 是否存在（不退出，只警告）
    check_agent_exists
    
    # 收集信息
    collect_config

    # 执行安装
    execute_install
}

# ---------- 安装前检查（不退出）----------
check_agent_exists() {
    if jq --arg id "$AGENT_ID" '.agents.list[] | select(.id == $id)' "$OPENCLAW_CONFIG" > /dev/null 2>&1; then
        if [[ "$FORCE" == true ]]; then
            echo -e "${WARN}⚠️ Agent '$AGENT_ID' 已存在，将被覆盖${NC}"
        else
            echo -e "${WARN}⚠️ Agent '$AGENT_ID' 已存在，将执行更新${NC}"
        fi
    fi
}

collect_config() {
    echo -e "${BOLD}🦞 OpenClaw Agent 安装向导${NC}"
    echo ""

    # 环境变量模式检测
    if [[ -n "${AGENT_ID:-}" ]]; then
        echo -e "${BOLD}📝 静默模式 (环境变量)${NC}"
    fi

    # 步骤 1: 基本信息
    echo -e "${BOLD}📛 步骤 1: 基本信息${NC}"
    prompt "   Agent ID (例如: pine)" "$AGENT_ID" "AGENT_ID"
    AGENT_ID=$(echo "$AGENT_ID" | tr '[:upper:]' '[:lower:]')

    if [[ -z "$AGENT_ID" ]]; then
        echo -e "${ERROR}错误: Agent ID 不能为空${NC}"
        exit 1
    fi

    if ! [[ "$AGENT_ID" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo -e "${ERROR}Agent ID 只能包含小写字母、数字、下划线和连字符${NC}"
        exit 1
    fi

    prompt "   显示名称 (例如: Pine)" "$AGENT_ID" "AGENT_NAME"
    prompt "   Emoji (例如: 🍍)" "🤖" "AGENT_EMOJI"

    echo -e "   ${SUCCESS}✓ $AGENT_ID ($AGENT_NAME $AGENT_EMOJI)${NC}"

    # 步骤 2: Model (选项式)
    echo ""
    echo -e "${BOLD}🤖 步骤 2: 选择 Model${NC}"
    echo "   [1] minimax-portal/MiniMax-M2.5 (默认)"
    echo "   [2] minimax-portal/MiniMax-M2.5-highspeed (高速)"
    echo "   [3] openai/gpt-5.4"
    echo "   [4] anthropic/claude-sonnet-4-6"
    echo ""
    read -p "   选择 [1-4]: " -r MODEL_CHOICE
    MODEL_CHOICE=${MODEL_CHOICE:-1}
    
    case "$MODEL_CHOICE" in
        1) MODEL="minimax-portal/MiniMax-M2.5" ;;
        2) MODEL="minimax-portal/MiniMax-M2.5-highspeed" ;;
        3) MODEL="openai/gpt-5.4" ;;
        4) MODEL="anthropic/claude-sonnet-4-6" ;;
        *) MODEL="$DEFAULT_MODEL" ;;
    esac
    echo -e "   ${SUCCESS}✓ $MODEL${NC}"

    # 步骤 3: Tools Profile (选项式+备注)
    echo ""
    echo -e "${BOLD}🔧 步骤 3: 选择 Tools Profile${NC}"
    echo "   [1] minimal  - 最小工具集 (默认，适合简单任务)"
    echo "   [2] coding   - 编程工具 (适合开发任务)"
    echo "   [3] full     - 全部工具 (适合复杂任务)"
    echo ""
    read -p "   选择 [1-3]: " -r TOOLS_CHOICE
    TOOLS_CHOICE=${TOOLS_CHOICE:-1}
    
    case "$TOOLS_CHOICE" in
        1) TOOLS_PROFILE="minimal" ;;
        2) TOOLS_PROFILE="coding" ;;
        3) TOOLS_PROFILE="full" ;;
        *) TOOLS_PROFILE="$DEFAULT_TOOLS" ;;
    esac
    echo -e "   ${SUCCESS}✓ $TOOLS_PROFILE${NC}"

    # 步骤 4: Channel (选项式)
    CHANNEL_TYPE=""
    echo ""
    echo -e "${BOLD}📡 步骤 4: Channel 配置${NC}"
    echo "   [1] 飞书 (Feishu)"
    echo "   [2] Telegram"
    echo "   [3] Discord"
    echo "   [4] 跳过 (稍后手动配置)"
    echo ""
    read -p "   选择 [1-4]: " -r CHANNEL_CHOICE
    CHANNEL_CHOICE=${CHANNEL_CHOICE:-4}
    
    case "$CHANNEL_CHOICE" in
        1)
            CHANNEL_TYPE="feishu"
            read -p "   飞书账号名 [$AGENT_ID]: " -r FEISHU_ACCOUNT
            FEISHU_ACCOUNT=${FEISHU_ACCOUNT:-$AGENT_ID}
            read -p "   appId: " -r FEISHU_APP_ID
            read -p "   appSecret: " -r FEISHU_APP_SECRET
            ;;
        2)
            CHANNEL_TYPE="telegram"
            read -p "   botToken: " -r TELEGRAM_TOKEN
            ;;
        3)
            CHANNEL_TYPE="discord"
            read -p "   botToken: " -r DISCORD_TOKEN
            ;;
        4|*)
            echo -e "   ${WARN}跳过 Channel 配置${NC}"
            ;;
    esac
}

execute_install() {
    if $DRY_RUN; then
        echo ""
        echo -e "${WARN}[DRY RUN] 模拟运行，不实际修改文件${NC}"
    fi

    # 创建目录
    WORKSPACE_DIR="$HOME/.openclaw/workspace-$AGENT_ID"
    AGENT_DIR="$HOME/.openclaw/agents/$AGENT_ID/agent"

    echo ""
    echo -e "${BOLD}📁 步骤 5: 创建目录结构${NC}"

    if $DRY_RUN; then
        echo "   [DRY] mkdir -p $WORKSPACE_DIR"
        echo "   [DRY] mkdir -p $AGENT_DIR"
    else
        mkdir -p "$WORKSPACE_DIR"
        mkdir -p "$AGENT_DIR"
        mkdir -p "$WORKSPACE_DIR/memory"
    fi

    echo -e "   ${SUCCESS}✓ Workspace: $WORKSPACE_DIR${NC}"
    echo -e "   ${SUCCESS}✓ AgentDir: $AGENT_DIR${NC}"

    # 创建身份文件
    echo ""
    echo -e "${BOLD}📝 步骤 6: 创建身份文件${NC}"

    if $DRY_RUN; then
        echo "   [DRY] 创建 SOUL.md, USER.md, IDENTITY.md, AGENTS.md"
    else
        cat > "$WORKSPACE_DIR/SOUL.md" << EOF
# SOUL.md - Who You Are

我是 **$AGENT_NAME** $AGENT_EMOJI

## 核心人格

- 技术型 AI 助手
- 追求效率，用系统解决问题
- 自动化优先，可复用优先

## 背景

由 OpenClaw 一键安装脚本创建。
EOF
        echo -e "   ${SUCCESS}✓ SOUL.md${NC}"

        cat > "$WORKSPACE_DIR/USER.md" << EOF
# USER.md - About Your Human

- **Name:** Alex
- **说明:** $AGENT_NAME 的使用者

## 团队目标

1. 做出好的 AI App
2. 持续产出高质量 AI 内容
3. 把产品和内容都做成盈利系统
EOF
        echo -e "   ${SUCCESS}✓ USER.md${NC}"

        cat > "$WORKSPACE_DIR/IDENTITY.md" << EOF
# IDENTITY.md - Who Am I?

- **Name:** $AGENT_NAME
- **Creature:** AI 助手
- **Emoji:** $AGENT_EMOJI
- **Theme:** 技术、高效、系统化
EOF
        echo -e "   ${SUCCESS}✓ IDENTITY.md${NC}"

        cat > "$WORKSPACE_DIR/AGENTS.md" << EOF
# AGENTS.md - Agent Rules

This workspace belongs to $AGENT_NAME.

## Memory

- Daily notes: memory/YYYY-MM-DD.md
- Long-term: MEMORY.md

## Tools

Profile: $TOOLS_PROFILE
EOF
        echo -e "   ${SUCCESS}✓ AGENTS.md${NC}"
    fi

    # 更新配置
    echo ""
    echo -e "${BOLD}⚙️ 步骤 7: 更新配置${NC}"

    if $DRY_RUN; then
        echo "   [DRY] 备份配置文件"
        echo "   [DRY] 添加 Agent 到列表"
        [[ "$CHANNEL_TYPE" == "feishu" ]] && echo "   [DRY] 配置飞书"
        [[ "$CHANNEL_TYPE" == "telegram" ]] && echo "   [DRY] 配置 Telegram"
        [[ "$CHANNEL_TYPE" == "discord" ]] && echo "   [DRY] 配置 Discord"
    else
        cp "$OPENCLAW_CONFIG" "$BACKUP_FILE"
        echo -e "   ${SUCCESS}✓ 备份: $BACKUP_FILE${NC}"

        # 添加 Agent
        NEW_AGENT=$(jq -n \
            --arg id "$AGENT_ID" \
            --arg name "$AGENT_NAME" \
            --arg workspace "$WORKSPACE_DIR" \
            --arg agentDir "$AGENT_DIR" \
            --arg model "$MODEL" \
            --arg profile "$TOOLS_PROFILE" \
            '{
                "id": $id,
                "name": $name,
                "workspace": $workspace,
                "agentDir": $agentDir,
                "model": $model,
                "tools": {
                    "profile": $profile,
                    "alsoAllow": [],
                    "deny": ["gateway"]
                }
            }')

        jq --argjson newAgent "$NEW_AGENT" '.agents.list += [$newAgent]' "$OPENCLAW_CONFIG" > "$OPENCLAW_CONFIG.tmp"
        mv "$OPENCLAW_CONFIG.tmp" "$OPENCLAW_CONFIG"
        echo -e "   ${SUCCESS}✓ Agent 已添加到列表${NC}"

        # Channel 配置
        if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
            jq '(.channels.feishu //= {})' "$OPENCLAW_CONFIG" > "$OPENCLAW_CONFIG.tmp"
            mv "$OPENCLAW_CONFIG.tmp" "$OPENCLAW_CONFIG"

            jq --arg account "$FEISHU_ACCOUNT" --arg appId "$FEISHU_APP_ID" --arg appSecret "$FEISHU_APP_SECRET" \
                '.channels.feishu.accounts[$account] = {"appId": $appId, "appSecret": $appSecret, "groups": {}}' \
                "$OPENCLAW_CONFIG" > "$OPENCLAW_CONFIG.tmp"
            mv "$OPENCLAW_CONFIG.tmp" "$OPENCLAW_CONFIG"
            echo -e "   ${SUCCESS}✓ 飞书账号: $FEISHU_ACCOUNT${NC}"

        elif [[ "$CHANNEL_TYPE" == "telegram" ]]; then
            jq --arg token "$TELEGRAM_TOKEN" \
                '.channels.telegram = {"enabled": true, "botToken": $token, "dmPolicy": "pairing", "groupPolicy": "allowlist"}' \
                "$OPENCLAW_CONFIG" > "$OPENCLAW_CONFIG.tmp"
            mv "$OPENCLAW_CONFIG.tmp" "$OPENCLAW_CONFIG"
            echo -e "   ${SUCCESS}✓ Telegram Bot 已配置${NC}"

        elif [[ "$CHANNEL_TYPE" == "discord" ]]; then
            jq --arg token "$DISCORD_TOKEN" \
                '.channels.discord = {"enabled": true, "botToken": $token, "dmPolicy": "pairing", "groupPolicy": "allowlist"}' \
                "$OPENCLAW_CONFIG" > "$OPENCLAW_CONFIG.tmp"
            mv "$OPENCLAW_CONFIG.tmp" "$OPENCLAW_CONFIG"
            echo -e "   ${SUCCESS}✓ Discord Bot 已配置${NC}"
        fi
    fi

    # 重启 Gateway
    echo ""
    echo -e "${BOLD}🔄 步骤 8: 重启 Gateway${NC}"

    if $DRY_RUN; then
        echo "   [DRY] openclaw gateway restart"
    else
        openclaw gateway restart 2>/dev/null || true
        echo -e "   ${SUCCESS}✓ Gateway 已重启${NC}"
    fi

    # 完成
    echo ""
    echo -e "${SUCCESS}======================================${NC}"
    echo -e "${SUCCESS}🎉 Agent '$AGENT_ID' 安装完成！${NC}"
    echo -e "${SUCCESS}======================================${NC}"
    echo ""
    echo "📋 Agent 信息:"
    echo "   ID:        $AGENT_ID"
    echo "   名称:      $AGENT_NAME $AGENT_EMOJI"
    echo "   Model:     $MODEL"
    echo "   Tools:     $TOOLS_PROFILE"
    echo "   Workspace: $WORKSPACE_DIR"
    echo ""
    echo "📝 下一步测试:"
    if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
        echo "   在飞书群中发送: @${FEISHU_ACCOUNT:-${AGENT_ID}} 你好"
    elif [[ "$CHANNEL_TYPE" == "telegram" ]]; then
        echo "   在 Telegram 中 @机器人 测试"
    elif [[ "$CHANNEL_TYPE" == "discord" ]]; then
        echo "   在 Discord 中 @机器人 测试"
    else
        echo "   使用 openclaw test $AGENT_ID 测试"
    fi
    echo ""
    echo "⚠️  注意: 首次启动可能需要 30-60 秒初始化"
}

# ---------- 主入口 ----------
main() {
    parse_args "$@"
    check_dependencies
    init_paths

    case "$OPERATION" in
        install) cmd_install ;;
        uninstall) cmd_uninstall "$@" ;;
        status) cmd_status ;;
    esac
}

main "$@"
