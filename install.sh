#!/bin/bash
# =============================================================================
# Claw Grow - Agent 安装向导 v2.3.0
# 支持：人类交互模式 / Agent 静默模式
# =============================================================================

set -uo pipefail

readonly VERSION="2.3.0"

# ---------- 颜色 ----------
readonly BOLD='\033[1m'
readonly SUCCESS='\033[38;2;0;229;204m'
readonly ERROR='\033[38;2;230;57;70m'
readonly WARN='\033[38;2;255;176;32m'
readonly NC='\033[0m'

# ---------- 全局变量 ----------
AGENT_ID="clawgrow"
AGENT_NAME="龙虾成长"
AGENT_EMOJI="🦞"
MODEL=""
CHANNEL_TYPE=""
SILENT_MODE=false
AUTO_CONFIRM=false

# ---------- tty 检测 ----------
is_interactive() {
    [[ -t 0 ]]
}

# ---------- 读取输入 ----------
read_line() {
    if is_interactive && [[ -c /dev/tty ]]; then
        read -r "$@" </dev/tty
    else
        read -r "$@" </dev/stdin
    fi
}

# ---------- 解析参数 ----------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_CONFIRM=true ;;
            -s|--silent) SILENT_MODE=true ;;
            -h|--help) show_help; exit 0 ;;
            *) echo -e "${ERROR}未知参数: $1${NC}"; show_help; exit 1 ;;
        esac
        shift
    done
}

show_help() {
    cat << HELP
Claw Grow Agent 安装向导 v${VERSION}

用法: 
  交互模式: curl -fsSL .../install.sh | bash
  静默模式: MODEL=xxx CHANNEL_TYPE=feishu ... bash <(...) --silent

选项:
  -y, --yes     自动确认
  -s, --silent  静默模式
  -h, --help    显示帮助
HELP
}

# ---------- 输出结构化清单（Agent 模式） ----------
print_agent_checklist() {
    cat << 'CHECKLIST'

================================================================================
CLAW_GROW_INSTALL_REQUIRED=true
================================================================================

请按以下步骤向用户收集信息：

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 1：基本信息
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  AGENT_NAME   显示名称（默认：龙虾成长）
  AGENT_EMOJI  Emoji（默认：🦞）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 2：模型选择
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MODEL_OPTIONS:
  1=minimax/MiniMax-M2.5
  2=minimax/MiniMax-M2.5-highspeed
  3=anthropic/claude-sonnet-4-6
  4=openai/gpt-5.4
  5=moonshot/kimi-k2.5
  6=ollama/qwen2.5:14b
  7=ollama/deepseek-r1:32b
  8=custom

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 3：通道选择
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHANNEL_OPTIONS:
  1=feishu   → 追问: FEISHU_ACCOUNT, FEISHU_APP_ID, FEISHU_APP_SECRET
  2=telegram → 追问: TELEGRAM_TOKEN
  3=discord  → 追问: DISCORD_TOKEN
  4=slack    → 追问: SLACK_TOKEN
  5=skip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
收集完成后执行安装命令：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AGENT_NAME="${AGENT_NAME}" \
AGENT_EMOJI="${AGENT_EMOJI}" \
MODEL="${MODEL}" \
CHANNEL_TYPE="${CHANNEL_TYPE}" \
FEISHU_ACCOUNT="${FEISHU_ACCOUNT}" \
FEISHU_APP_ID="${FEISHU_APP_ID}" \
FEISHU_APP_SECRET="${FEISHU_APP_SECRET}" \
bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent

================================================================================
CHECKLIST
}

# ---------- 验证静默模式 ----------
validate_silent() {
    local missing=()
    
    [[ -z "$AGENT_NAME" ]] && missing+=("AGENT_NAME")
    [[ -z "$MODEL" ]] && missing+=("MODEL")
    [[ -z "$CHANNEL_TYPE" ]] && missing+=("CHANNEL_TYPE")
    
    case "$CHANNEL_TYPE" in
        feishu)
            [[ -z "$FEISHU_ACCOUNT" ]] && missing+=("FEISHU_ACCOUNT")
            [[ -z "$FEISHU_APP_ID" ]] && missing+=("FEISHU_APP_ID")
            [[ -z "$FEISHU_APP_SECRET" ]] && missing+=("FEISHU_APP_SECRET")
            ;;
        telegram) [[ -z "$TELEGRAM_TOKEN" ]] && missing+=("TELEGRAM_TOKEN") ;;
        discord) [[ -z "$DISCORD_TOKEN" ]] && missing+=("DISCORD_TOKEN") ;;
    esac
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${ERROR}❌ 缺少参数: ${missing[*]}${NC}"
        exit 1
    fi
}

# ---------- 交互函数 ----------
prompt() {
    local text="$1" default="$2" var="$3"
    echo ""
    echo -e "${BOLD}📝 $text${NC}"
    [[ -n "$default" ]] && echo "   (默认值: $default)"
    echo -n "   > "
    read_line
    
    if [[ -n "$REPLY" ]]; then
        eval "$var=\$REPLY"
    elif [[ -n "$default" ]]; then
        eval "$var=\$default"
    fi
    echo -e "   ${SUCCESS}✓ ${!var}${NC}"
}

prompt_menu() {
    local text="$1" options="$2" var="$3"
    
    while true; do
        echo ""
        echo -e "${BOLD}$text${NC}"
        echo ""
        echo "$options"
        echo ""
        echo -n "   请回复编号 > "
        read_line
        
        [[ -z "$REPLY" ]] && continue
        
        local selected
        case "$REPLY" in
            1) selected=$(echo "$options" | head -1 | cut -d= -f2) ;;
            2) selected=$(echo "$options" | sed -n '2p' | cut -d= -f2) ;;
            3) selected=$(echo "$options" | sed -n '3p' | cut -d= -f2) ;;
            4) selected=$(echo "$options" | sed -n '4p' | cut -d= -f2) ;;
            5) selected=$(echo "$options" | sed -n '5p' | cut -d= -f2) ;;
            6) selected=$(echo "$options" | sed -n '6p' | cut -d= -f2) ;;
            7) selected=$(echo "$options" | sed -n '7p' | cut -d= -f2) ;;
            8) selected="custom" ;;
            *) echo -e "${ERROR}⚠️ 无效选择${NC}"; continue ;;
        esac
        
        eval "$var=\$selected"
        echo -e "   ${SUCCESS}✓ 已选择${NC}"
        return 0
    done
}

# ---------- 安装流程 ----------
run_install() {
    echo ""
    echo -e "${BOLD}🦞 Claw Grow 安装向导${NC}"
    echo ""

    # 步骤 1: 基本信息
    echo -e "${BOLD}步骤 1: 基本信息${NC}"
    prompt "显示名称" "龙虾成长" "AGENT_NAME"
    prompt "Emoji" "🦞" "AGENT_EMOJI"

    # 步骤 2: 模型选择
    echo ""
    echo -e "${BOLD}步骤 2: 选择模型${NC}"
    local models="  1=minimax/MiniMax-M2.5
  2=minimax/MiniMax-M2.5-highspeed
  3=anthropic/claude-sonnet-4-6
  4=openai/gpt-5.4
  5=moonshot/kimi-k2.5
  6=ollama/qwen2.5:14b
  7=ollama/deepseek-r1:32b
  8=custom"
    prompt_menu "请选择模型" "$models" "MODEL"

    # 步骤 3: 通道选择
    echo ""
    echo -e "${BOLD}步骤 3: 选择通道${NC}"
    local channels="  1=feishu
  2=telegram
  3=discord
  4=slack
  5=skip"
    prompt_menu "请选择通信通道" "$channels" "CHANNEL_TYPE"

    # 追问凭据
    case "$CHANNEL_TYPE" in
        feishu)
            echo ""
            echo -e "${BOLD}🔐 飞书配置${NC}"
            echo "   获取: https://open.feishu.cn → 应用 → 凭证"
            prompt "账号名" "$AGENT_ID" "FEISHU_ACCOUNT"
            prompt "App ID" "" "FEISHU_APP_ID"
            prompt "App Secret" "" "FEISHU_APP_SECRET"
            ;;
        telegram)
            prompt "Bot Token" "" "TELEGRAM_TOKEN"
            ;;
        discord)
            prompt "Bot Token" "" "DISCORD_TOKEN"
            ;;
    esac

    # 确认
    echo ""
    echo -e "${BOLD}步骤 4: 确认${NC}"
    echo ""
    echo "   Agent: $AGENT_NAME $AGENT_EMOJI"
    echo "   模型: $MODEL"
    echo "   通道: $CHANNEL_TYPE"
    echo ""
    
    if [[ "$AUTO_CONFIRM" != "true" ]]; then
        echo -n "   确认安装? [Y/n] > "
        read_line
        [[ "$REPLY" =~ ^[Nn]$ ]] && echo "已取消" && exit 0
    fi

    execute
}

# ---------- 执行安装 ----------
execute() {
    echo ""
    echo -e "${BOLD}🔧 开始安装...${NC}"
    echo ""

    echo "   [1/2] 创建 Agent..."
    local cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"
    
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        case "$CHANNEL_TYPE" in
            feishu) cmd="$cmd --bind feishu:$FEISHU_ACCOUNT" ;;
            *) cmd="$cmd --bind $CHANNEL_TYPE" ;;
        esac
    fi

    echo "   $cmd"
    eval $cmd 2>/dev/null || {
        cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"
        eval $cmd || { echo -e "${ERROR}❌ 创建失败${NC}"; exit 1; }
    }
    echo "   ✓ Agent 创建成功"

    # 更新配置
    echo ""
    echo "   [2/2] 更新配置..."
    update_config

    echo ""
    echo -e "${SUCCESS}✓ 安装完成！${NC}"
    echo ""
    echo "运行: openclaw gateway restart"
}

update_config() {
    local json="$HOME/.openclaw/openclaw.json"
    [[ ! -f "$json" ]] && return
    
    if ! jq -e --arg a "$AGENT_ID" '.tools.agentToAgent.allow | index($a)' "$json" >/dev/null 2>&1; then
        jq --arg a "$AGENT_ID" '.tools.agentToAgent.allow += [$a]' "$json" > tmp_$$.json && mv tmp_$$.json "$json"
    fi
    
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        local account="${FEISHU_ACCOUNT:-$AGENT_ID}"
        local bind="{\"agentId\":\"$AGENT_ID\",\"match\":{\"channel\":\"$CHANNEL_TYPE\",\"accountId\":\"$account\"}}"
        jq --argjson b "$bind" '.bindings += [$b]' "$json" > tmp_$$.json && mv tmp_$$.json "$json"
    fi
}

# ---------- 主入口 ----------
main() {
    parse_args "$@"
    
    # 无 tty 且非静默模式 → 输出结构化清单
    if ! is_interactive && [[ "$SILENT_MODE" != "true" ]]; then
        print_agent_checklist
        exit 0
    fi
    
    # 静默模式
    [[ "$SILENT_MODE" == "true" ]] && validate_silent && execute && exit 0
    
    # 交互模式
    run_install
}

main "$@"
