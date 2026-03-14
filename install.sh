#!/bin/bash
set -uo pipefail

# =============================================================================
# Claw Grow - Agent 安装向导
# 支持：人类交互模式 / Agent 静默模式
# =============================================================================

readonly SCRIPT_VERSION="2.1.1"

# ---------- 颜色 ----------
BOLD='\033[1m'
SUCCESS='\033[38;2;0;229;204m'
ERROR='\033[38;2;230;57;70m'
WARN='\033[38;2;255;176;32m'
INFO='\033[38;2;97;175;239m'
NC='\033[0m'

# ---------- 全局变量 ----------
AGENT_ID="clawgrow"
AGENT_NAME="龙虾成长"
AGENT_EMOJI="🦞"
MODEL=""
CHANNEL_TYPE=""
SILENT_MODE=false
INTERACTIVE_MODE=false

# ---------- tty 检测 ----------
detect_tty() {
    # 检查 stdin 是否有 tty（人类终端）
    # -t 0 检查 stdin，-t 1 检查 stdout
    # 如果 stdin 有 tty，说明是人类在终端直接运行
    if [[ -t 0 ]]; then
        INTERACTIVE_MODE=true
    else
        INTERACTIVE_MODE=false
    fi
}

# ---------- 安全读取（兼容管道模式） ----------
# 交互模式从 /dev/tty 读取，管道模式从 stdin 读取
read_input() {
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        read -r "$@" </dev/tty
    else
        read -r "$@"
    fi
}

# ---------- 输出函数 ----------
print_agent_checklist() {
    cat << 'EOF'

================================================================================
CLAW_GROW_INSTALL_REQUIRED=true
================================================================================

# 模型厂商分组 (MODEL_GROUPS)
MODEL_GROUPS='[
  {"id":1,"name":"MiniMax","desc":"高性价比，国内访问快"},
  {"id":2,"name":"Anthropic","desc":"Claude 系列"},
  {"id":3,"name":"OpenAI","desc":"GPT 系列"},
  {"id":4,"name":"Moonshot","desc":"Kimi 系列"},
  {"id":5,"name":"开源模型","desc":"DeepSeek / Qwen / Llama"},
  {"id":6,"name":"Venice","desc":"隐私优先，匿名化"},
  {"id":7,"name":"聚合路由","desc":"OpenRouter / Together / Mistral"},
  {"id":8,"name":"本地部署","desc":"Ollama / vLLM"},
  {"id":9,"name":"其他","desc":"NVIDIA / GLM / MiMo / LiteLLM"}
]'

# 模型选项 (MODEL_OPTIONS) - 按厂商分组
MODEL_OPTIONS='[
  {"id":"1.1","group":1,"name":"MiniMax M2.5","desc":"200k上下文","value":"minimax/MiniMax-M2.5"},
  {"id":"1.2","group":1,"name":"M2.5 高速版","desc":"更快响应","value":"minimax/MiniMax-M2.5-highspeed"},
  {"id":"1.3","group":1,"name":"M2.5 闪电版","desc":"极速","value":"minimax/MiniMax-M2.5-Lightning"},
  {"id":"2.1","group":2,"name":"Claude Opus 4.6","desc":"最强推理","value":"anthropic/claude-opus-4-6"},
  {"id":"2.2","group":2,"name":"Claude Sonnet 4.6","desc":"平衡性能","value":"anthropic/claude-sonnet-4-6"},
  {"id":"2.3","group":2,"name":"Claude Haiku 4.6","desc":"极速轻量","value":"anthropic/claude-haiku-4-6"},
  {"id":"3.1","group":3,"name":"GPT-5.4","desc":"1M上下文","value":"openai/gpt-5.4"},
  {"id":"4.1","group":4,"name":"Kimi K2.5","desc":"256k上下文","value":"moonshot/kimi-k2.5"},
  {"id":"5.1","group":5,"name":"DeepSeek R1","desc":"推理强","value":"huggingface/deepseek-ai/DeepSeek-R1"},
  {"id":"6.1","group":6,"name":"Venice","desc":"匿名化","value":"venice/llama-3.3-70b"}
]'

# 通道选项 (CHANNEL_OPTIONS)
CHANNEL_OPTIONS='[
  {"id":1,"name":"飞书","value":"feishu","fields":["FEISHU_ACCOUNT","FEISHU_APP_ID","FEISHU_APP_SECRET"]},
  {"id":2,"name":"Telegram","value":"telegram","fields":["TELEGRAM_TOKEN"]},
  {"id":3,"name":"Discord","value":"discord","fields":["DISCORD_TOKEN"]},
  {"id":4,"name":"Slack","value":"slack","fields":["SLACK_TOKEN"]},
  {"id":5,"name":"跳过","value":"skip","fields":[]}
]'

# 使用方法见下方
EOF
}

# ---------- 解析参数 ----------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_CONFIRM=true ;;
            -s|--silent) SILENT_MODE=true ;;
            -h|--help) show_help; exit 0 ;;
            *) echo -e "${ERROR}未知选项: $1${NC}"; show_help; exit 1 ;;
        esac
        shift
    done
}

show_help() {
    cat << HELP_EOF
Claw Grow Agent 安装向导 v${SCRIPT_VERSION}

用法: 
  交互模式: curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash
  静默模式: AGENT_NAME="🦞" MODEL="minimax/MiniMax-M2.5" CHANNEL_TYPE="feishu" FEISHU_APP_ID="xxx" FEISHU_APP_SECRET="xxx" bash <(curl -fsSL ...) --silent

选项:
  -y, --yes     自动确认
  -s, --silent  静默模式
  -h, --help    显示帮助
HELP_EOF
}

# ---------- 交互函数 ----------
prompt() {
    local prompt_text="$1"
    local default="$2"
    local var_name="$3"

    echo ""
    echo -e "${BOLD}📝 $prompt_text${NC}"
    [[ -n "$default" ]] && echo "   (默认值: $default)"
    echo -n "   > "
    read_input -r

    if [[ -n "$REPLY" ]]; then
        eval "$var_name=\$REPLY"
    elif [[ -n "$default" ]]; then
        eval "$var_name=\$default"
    fi

    echo -e "   ${SUCCESS}✓ ${!var_name}${NC}"
}

prompt_choice() {
    local prompt_text="$1"
    local options_json="$2"
    local var_name="$3"

    while true; do
        echo ""
        echo -e "${BOLD}$prompt_text${NC}"
        echo ""

        local count=1
        for option in $(echo "$options_json" | jq -r '.[] | @base64'); do
            local id label desc
            id=$(echo "$option" | base64 -d | jq -r '.id')
            label=$(echo "$option" | base64 -d | jq -r '.name')
            desc=$(echo "$option" | base64 -d | jq -r '.desc // empty')
            echo "   [$id] $label${desc:+ - $desc}"
        done

        echo ""
        echo -n "   请回复编号 > "
        read_input -r

        if [[ -z "$REPLY" ]]; then
            echo -e "${ERROR}⚠️ 请输入有效选项${NC}"
            continue
        fi

        if [[ "$REPLY" =~ ^[0-9]+$ ]] && [[ "$REPLY" -ge 1 ]] && [[ "$REPLY" -le 10 ]]; then
            local selected
            selected=$(echo "$options_json" | jq -r ".[] | select(.id == $REPLY) | .value")
            if [[ -n "$selected" ]]; then
                eval "$var_name=\$selected"
                local selected_name
                selected_name=$(echo "$options_json" | jq -r ".[] | select(.id == $REPLY) | .name")
                echo -e "   ${SUCCESS}✓ 已选择: $selected_name${NC}"
                return 0
            fi
        fi
        
        echo -e "${ERROR}⚠️ 无效选择，请重新选择${NC}"
    done
}

# ---------- 静默模式验证 ----------
validate_silent_mode() {
    local missing_fields=()
    
    [[ -z "$AGENT_NAME" ]] && missing_fields+=("AGENT_NAME")
    [[ -z "$AGENT_EMOJI" ]] && missing_fields+=("AGENT_EMOJI")
    [[ -z "$MODEL" ]] && missing_fields+=("MODEL")
    [[ -z "$CHANNEL_TYPE" ]] && missing_fields+=("CHANNEL_TYPE")
    
    case "$CHANNEL_TYPE" in
        feishu)
            [[ -z "$FEISHU_ACCOUNT" ]] && missing_fields+=("FEISHU_ACCOUNT")
            [[ -z "$FEISHU_APP_ID" ]] && missing_fields+=("FEISHU_APP_ID")
            [[ -z "$FEISHU_APP_SECRET" ]] && missing_fields+=("FEISHU_APP_SECRET")
            ;;
        telegram) [[ -z "$TELEGRAM_TOKEN" ]] && missing_fields+=("TELEGRAM_TOKEN") ;;
        discord) [[ -z "$DISCORD_TOKEN" ]] && missing_fields+=("DISCORD_TOKEN") ;;
        slack) [[ -z "$SLACK_TOKEN" ]] && missing_fields+=("SLACK_TOKEN") ;;
    esac
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        echo -e "${ERROR}❌ 静默模式缺少必要参数:${NC}"
        for field in "${missing_fields[@]}"; do echo "   - $field"; done
        exit 1
    fi
}

# ---------- 安装流程（交互模式） ----------
install_interactive() {
    echo ""
    echo -e "${BOLD}🦞 Claw Grow Agent 安装向导${NC}"
    echo ""

    # 步骤 1: 基本信息
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 1: 基本信息${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    AGENT_ID="clawgrow"
    echo "   Agent ID: $AGENT_ID (固定)"

    prompt "请输入显示名称" "龙虾成长" "AGENT_NAME"
    prompt "请输入 Emoji" "🦞" "AGENT_EMOJI"

    # 步骤 2: 选择模型
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 2: 选择模型${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local models_json
    models_json=$(cat << 'EOF'
[
  {"id":1,"value":"minimax/MiniMax-M2.5","name":"MiniMax M2.5","desc":"200k上下文"},
  {"id":2,"value":"minimax/MiniMax-M2.5-highspeed","name":"M2.5 高速版","desc":"更快响应"},
  {"id":3,"value":"anthropic/claude-sonnet-4-6","name":"Claude Sonnet 4.6","desc":"平衡性能"},
  {"id":4,"value":"openai/gpt-5.4","name":"GPT-5.4","desc":"1M上下文"},
  {"id":5,"value":"moonshot/kimi-k2.5","name":"Kimi K2.5","desc":"256k上下文"},
  {"id":6,"value":"huggingface/deepseek-ai/DeepSeek-R1","name":"DeepSeek R1","desc":"推理强"}
]
EOF
    )
    prompt_choice "请选择模型" "$models_json" "MODEL"

    # 步骤 3: 选择通道
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 3: 选择通信通道${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local channels_json
    channels_json=$(cat << 'EOF'
[
  {"id":1,"value":"feishu","name":"飞书","desc":"需要 App ID + Secret"},
  {"id":2,"value":"telegram","name":"Telegram","desc":"需要 Bot Token"},
  {"id":3,"value":"discord","name":"Discord","desc":"需要 Bot Token"},
  {"id":4,"value":"skip","name":"跳过","desc":"稍后手动配置"}
]
EOF
    )
    prompt_choice "请选择通信通道" "$channels_json" "CHANNEL_TYPE"

    # 追问凭据
    case "$CHANNEL_TYPE" in
        feishu)
            echo ""
            echo -e "${BOLD}🔐 飞书配置${NC}"
            echo "   获取地址: https://open.feishu.cn → 应用 → 凭证与基础信息"
            prompt "飞书账号名" "$AGENT_ID" "FEISHU_ACCOUNT"
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

    # 步骤 4: 确认
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 4: 确认安装${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "   Agent ID: $AGENT_ID"
    echo "   显示名称: $AGENT_NAME $AGENT_EMOJI"
    echo "   模型: $MODEL"
    echo "   通道: $CHANNEL_TYPE"
    echo ""

    if [[ "$AUTO_CONFIRM" != "true" ]]; then
        echo -n "   确认安装? [Y/n] > "
        read_input -r
        if [[ "$REPLY" != "y" && "$REPLY" != "Y" && -n "$REPLY" ]]; then
            echo "已取消"
            exit 0
        fi
    fi

    execute_install
}

# ---------- 执行安装 ----------
execute_install() {
    echo ""
    echo -e "${BOLD}🔧 开始安装...${NC}"
    echo ""

    echo "   [1/3] 创建 Agent..."
    local cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"
    
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
            cmd="$cmd --bind feishu:$FEISHU_ACCOUNT"
        else
            cmd="$cmd --bind $CHANNEL_TYPE"
        fi
    fi

    echo "   执行: $cmd"
    eval $cmd || {
        # 尝试不绑定通道
        cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"
        eval $cmd || {
            echo -e "${ERROR}❌ 创建失败${NC}"
            exit 1
        }
    }
    echo "   ✓ Agent 创建成功"

    # 更新配置
    echo ""
    echo "   [2/3] 更新配置..."
    update_config

    echo ""
    echo -e "${SUCCESS}✓ 安装完成！${NC}"
    echo ""
    echo "请运行: openclaw gateway restart"
}

update_config() {
    local json_file="$HOME/.openclaw/openclaw.json"
    [[ ! -f "$json_file" ]] && return
    
    # 添加到 agentToAgent.allow
    if ! jq -e --arg agent "$AGENT_ID" '.tools.agentToAgent.allow | index($agent)' "$json_file" >/dev/null 2>&1; then
        jq --arg agent "$AGENT_ID" '.tools.agentToAgent.allow += [$agent]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
    fi
    
    # 添加 binding
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        local account_id="${FEISHU_ACCOUNT:-$AGENT_ID}"
        local binding_json="{\"agentId\":\"$AGENT_ID\",\"match\":{\"channel\":\"$CHANNEL_TYPE\",\"accountId\":\"$account_id\"}}"
        jq --argjson binding "$binding_json" '.bindings += [$binding]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
    fi
}

# ---------- 主入口 ----------
main() {
    detect_tty
    parse_args "$@"
    
    # Agent 模式：无 tty 且非静默模式
    if [[ "$INTERACTIVE_MODE" == "false" ]] && [[ "$SILENT_MODE" == "false" ]]; then
        print_agent_checklist
        exit 0
    fi
    
    # 静默模式
    if [[ "$SILENT_MODE" == "true" ]]; then
        validate_silent_mode
        execute_install
        exit 0
    fi
    
    # 交互模式
    install_interactive
}

main "$@"
