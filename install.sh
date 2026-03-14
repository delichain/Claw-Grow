#!/bin/bash
# =============================================================================
# Claw Grow - Agent 安装向导 v2.2.0
# 支持：人类交互模式 / Agent 静默模式
# =============================================================================

set -uo pipefail

readonly VERSION="2.2.0"

# ---------- 颜色 ----------
readonly BOLD='\033[1m'
readonly SUCCESS='\033[38;2:0;229;204m'
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
    # 检查 stdin 是否有 tty
    [[ -t 0 ]]
}

# ---------- 读取输入 ----------
# 交互模式从 /dev/tty 读取，管道模式从 stdin 读取
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
    cat << 'EOF'

================================================================================
CLAW_GROW_INSTALL_REQUIRED=true
================================================================================

# MODEL_GROUPS - 厂商分组
MODEL_GROUPS='[{"id":1,"name":"MiniMax"},{"id":2,"name":"Anthropic"},{"id":3,"name":"OpenAI"},{"id":4,"name":"Moonshot"},{"id":5,"name":"开源"}]'

# MODEL_OPTIONS - 型号选项 (按 group 分)
MODEL_OPTIONS='[
  {"id":"1.1","group":1,"value":"minimax/MiniMax-M2.5","name":"M2.5","desc":"200k上下文"},
  {"id":"1.2","group":1,"value":"minimax/MiniMax-M2.5-highspeed","name":"M2.5 高速版","desc":"更快"},
  {"id":"2.1","group":2,"value":"anthropic/claude-sonnet-4-6","name":"Claude Sonnet","desc":"平衡"},
  {"id":"3.1","group":3,"value":"openai/gpt-5.4","name":"GPT-5.4","desc":"1M上下文"},
  {"id":"4.1","group":4,"value":"moonshot/kimi-k2.5","name":"Kimi K2.5","desc":"256k"},
  {"id":"5.1","group":5,"value":"huggingface/deepseek-ai/DeepSeek-R1","name":"DeepSeek R1","desc":"推理强"}
]'

# CHANNEL_OPTIONS - 通道选项
CHANNEL_OPTIONS='[
  {"id":1,"value":"feishu","name":"飞书","fields":["FEISHU_ACCOUNT","FEISHU_APP_ID","FEISHU_APP_SECRET"]},
  {"id":2,"value":"telegram","name":"Telegram","fields":["TELEGRAM_TOKEN"]},
  {"id":3,"value":"discord","name":"Discord","fields":["DISCORD_TOKEN"]},
  {"id":4,"value":"skip","name":"跳过","fields":[]}
]'

================================================================================
EOF
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
    local text="$1" json="$2" var="$3"
    local count=1
    
    while true; do
        echo ""
        echo -e "${BOLD}$text${NC}"
        echo ""
        
        # 解析 JSON 显示选项
        echo "$json" | jq -r '.[] | "   [\(.id)] \(.name)\(.desc // "")"' 2>/dev/null || {
            # JSON 解析失败时手动显示
            local i=1
            while IFS= read -r line; do
                echo "   [$i] $line"
                ((i++))
            done <<< "$json"
        }
        
        echo ""
        echo -n "   请回复编号 > "
        read_line
        
        [[ -z "$REPLY" ]] && continue
        [[ ! "$REPLY" =~ ^[0-9]+$ ]] && continue
        
        local selected
        selected=$(echo "$json" | jq -r ".[] | select(.id == $REPLY) | .value" 2>/dev/null)
        
        if [[ -n "$selected" ]]; then
            eval "$var=\$selected"
            echo -e "   ${SUCCESS}✓ 已选择${NC}"
            return 0
        fi
        
        echo -e "${ERROR}⚠️ 无效选择${NC}"
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

    # 步骤 2: 选择模型
    echo ""
    echo -e "${BOLD}步骤 2: 选择模型${NC}"
    local models='[
      {"id":1,"value":"minimax/MiniMax-M2.5","name":"MiniMax M2.5","desc":" - 200k上下文"},
      {"id":2,"value":"minimax/MiniMax-M2.5-highspeed","name":"M2.5 高速版","desc":" - 更快"},
      {"id":3,"value":"anthropic/claude-sonnet-4-6","name":"Claude Sonnet","desc":" - 平衡"},
      {"id":4,"value":"openai/gpt-5.4","name":"GPT-5.4","desc":" - 1M上下文"},
      {"id":5,"value":"moonshot/kimi-k2.5","name":"Kimi K2.5","desc":" - 256k"},
      {"id":6,"value":"huggingface/deepseek-ai/DeepSeek-R1","name":"DeepSeek R1","desc":" - 推理"}
    ]'
    prompt_menu "请选择模型" "$models" "MODEL"

    # 步骤 3: 选择通道
    echo ""
    echo -e "${BOLD}步骤 3: 选择通道${NC}"
    local channels='[
      {"id":1,"value":"feishu","name":"飞书","desc":" - 需要 App ID+Secret"},
      {"id":2,"value":"telegram","name":"Telegram","desc":" - 需要 Bot Token"},
      {"id":3,"value":"discord","name":"Discord","desc":" - 需要 Bot Token"},
      {"id":4,"value":"skip","name":"跳过","desc":" - 稍后配置"}
    ]'
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

    # 执行
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
        # 重试不绑定
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
    
    # 添加到 allow 列表
    if ! jq -e --arg a "$AGENT_ID" '.tools.agentToAgent.allow | index($a)' "$json" >/dev/null 2>&1; then
        jq --arg a "$AGENT_ID" '.tools.agentToAgent.allow += [$a]' "$json" > tmp_$$.json && mv tmp_$$.json "$json"
    fi
    
    # 添加 binding
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
