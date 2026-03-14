#!/bin/bash
set -uo pipefail

# =============================================================================
# Claw Grow - Agent 安装向导
# 支持：人类交互模式 / Agent 静默模式
# =============================================================================

readonly SCRIPT_VERSION="2.1.0"

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
    # 检查是否有 tty（人类终端）
    if [[ -t 1 ]] && [[ -c /dev/tty ]]; then
        INTERACTIVE_MODE=true
    else
        INTERACTIVE_MODE=false
    fi
}

# ---------- 安全读取（兼容管道模式） ----------
# 交互模式从 /dev/tty 读取，管道模式从 stdin 读取
read_input() {
    if [[ "$INTERACTIVE_MODE" == "true" ]] && [[ -c /dev/tty ]]; then
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
  # MiniMax (1.x)
  {"id":"1.1","group":1,"name":"MiniMax M2.5","desc":"200k上下文，推理主力","value":"minimax/MiniMax-M2.5"},
  {"id":"1.2","group":1,"name":"MiniMax M2.5 高速版","desc":"更快响应","value":"minimax/MiniMax-M2.5-highspeed"},
  {"id":"1.3","group":1,"name":"MiniMax M2.5 闪电版","desc":"极速，适合高频调用","value":"minimax/MiniMax-M2.5-Lightning"},
  {"id":"1.4","group":1,"name":"MiniMax VL-01","desc":"支持视觉输入","value":"minimax/MiniMax-VL-01"},
  # Anthropic (2.x)
  {"id":"2.1","group":2,"name":"Claude Opus 4.6","desc":"最强推理","value":"anthropic/claude-opus-4-6"},
  {"id":"2.2","group":2,"name":"Claude Sonnet 4.6","desc":"平衡性能","value":"anthropic/claude-sonnet-4-6"},
  {"id":"2.3","group":2,"name":"Claude Haiku 4.6","desc":"极速轻量","value":"anthropic/claude-haiku-4-6"},
  # OpenAI (3.x)
  {"id":"3.1","group":3,"name":"GPT-5.4","desc":"1M上下文","value":"openai/gpt-5.4"},
  {"id":"3.2","group":3,"name":"GPT-5.4 Pro","desc":"Pro版","value":"openai/gpt-5.4-pro"},
  {"id":"3.3","group":3,"name":"O3","desc":"深度推理","value":"openai/o3"},
  {"id":"3.4","group":3,"name":"O3 Mini","desc":"Mini版","value":"openai/o3-mini"},
  # Moonshot (4.x)
  {"id":"4.1","group":4,"name":"Kimi K2.5","desc":"256k上下文","value":"moonshot/kimi-k2.5"},
  {"id":"4.2","group":4,"name":"Kimi K2 Thinking","desc":"推理版","value":"moonshot/kimi-k2-thinking"},
  {"id":"4.3","group":4,"name":"Kimi Coding","desc":"编程专用","value":"kimi-coding/k2p5"},
  # 开源 (5.x)
  {"id":"5.1","group":5,"name":"DeepSeek R1","desc":"推理能力强","value":"huggingface/deepseek-ai/DeepSeek-R1"},
  {"id":"5.2","group":5,"name":"Qwen3 8B","desc":"阿里开源","value":"huggingface/Qwen/Qwen3-8B"},
  {"id":"5.3","group":5,"name":"Llama 3.3 70B","desc":"Meta开源","value":"huggingface/meta-llama/Llama-3.3-70B-Instruct"},
  {"id":"5.4","group":5,"name":"GLM-5","desc":"智谱AI","value":"zai/glm-5"},
  {"id":"5.5","group":5,"name":"GLM-4.7","desc":"智谱AI","value":"zai/glm-4.7"},
  # Venice (6.x)
  {"id":"6.1","group":6,"name":"Venice Kimi","desc":"匿名化访问","value":"venice/llama-3.3-70b"},
  {"id":"6.2","group":6,"name":"Venice Claude","desc":"匿名化访问","value":"venice/claude-sonnet-4"},
  # 聚合路由 (7.x)
  {"id":"7.1","group":7,"name":"OpenRouter","desc":"多平台路由","value":"openrouter/anthropic/claude-sonnet-4"},
  {"id":"7.2","group":7,"name":"Together","desc":"多平台路由","value":"together/ai/Qwen3-8B"},
  # 本地部署 (8.x)
  {"id":"8.1","group":8,"name":"Ollama Qwen2.5","desc":"本地推理","value":"ollama/qwen2.5"},
  {"id":"8.2","group":8,"name":"Ollama Llama","desc":"本地推理","value":"ollama/llama3.3"},
  {"id":"8.3","group":8,"name":"Ollama DeepSeek","desc":"本地推理","value":"ollama/deepseek-r1"},
  # 其他 (9.x)
  {"id":"9.1","group":9,"name":"NVIDIA Nemotron","desc":"英伟达","value":"nvidia/nemotron-70b"},
  {"id":"9.2","group":9,"name":"MiMo V2","desc":"小米","value":"xiaomi/MiMo-V2"},
  {"id":"9.3","group":9,"name":"LiteLLM Claude","desc":"LiteLLM","value":"litellm/claude-sonnet-4"},
  {"id":"9.4","group":9,"name":"GLM","desc":"智谱","value":"zhipu/glm-4"}
]'

# 通道选项 (CHANNEL_OPTIONS)
CHANNEL_OPTIONS='[
  {"id":1,"name":"飞书","value":"feishu","fields":["FEISHU_ACCOUNT","FEISHU_APP_ID","FEISHU_APP_SECRET"]},
  {"id":2,"name":"Telegram","value":"telegram","fields":["TELEGRAM_TOKEN"]},
  {"id":3,"name":"Discord","value":"discord","fields":["DISCORD_TOKEN"]},
  {"id":4,"name":"Slack","value":"slack","fields":["SLACK_TOKEN"]},
  {"id":5,"name":"跳过","value":"skip","fields":[]}
]'

# 必填字段定义
REQUIRED_FIELDS='{
  "AGENT_NAME":{"required":true,"desc":"Agent显示名称"},
  "AGENT_EMOJI":{"required":true,"desc":"Emoji"},
  "MODEL":{"required":true,"desc":"模型ID"},
  "CHANNEL_TYPE":{"required":true,"desc":"通道类型"},
  "FEISHU_ACCOUNT":{"required":false,"desc":"飞书账号名","when":"feishu"},
  "FEISHU_APP_ID":{"required":false,"desc":"飞书App ID","when":"feishu"},
  "FEISHU_APP_SECRET":{"required":false,"desc":"飞书App Secret","when":"feishu"},
  "TELEGRAM_TOKEN":{"required":false,"desc":"Telegram Bot Token","when":"telegram"},
  "DISCORD_TOKEN":{"required":false,"desc":"Discord Bot Token","when":"discord"},
  "SLACK_TOKEN":{"required":false,"desc":"Slack Bot Token","when":"slack"}
}'

================================================================================
# 使用方法
================================================================================
# 
# 交互模式（人类终端）:
#   curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh | bash
#
# 静默模式（Agent）:
#   AGENT_NAME="🦞" MODEL="minimax/MiniMax-M2.5" CHANNEL_TYPE="feishu" \\
#   FEISHU_ACCOUNT="clawgrow" FEISHU_APP_ID="cli_xxx" FEISHU_APP_SECRET="xxx" \\
#   bash <(curl -fsSL https://raw.githubusercontent.com/delichain/Claw-Grow/main/install.sh) --silent
#
================================================================================

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
  -y, --yes     自动确认（交互模式）
  -s, --silent  静默模式（需要环境变量）
  -h, --help    显示帮助

环境变量（静默模式）:
  AGENT_NAME           Agent 显示名称
  AGENT_EMOJI          Emoji
  MODEL                模型 ID
  CHANNEL_TYPE         通道类型 (feishu/telegram/discord/slack/skip)
  FEISHU_ACCOUNT       飞书账号名 (feishu)
  FEISHU_APP_ID        飞书 App ID (feishu)
  FEISHU_APP_SECRET    飞书 App Secret (feishu)
  TELEGRAM_TOKEN       Telegram Bot Token
  DISCORD_TOKEN        Discord Bot Token
  SLACK_TOKEN          Slack Bot Token
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
    local allow_back="${4:-false}"

    while true; do
        echo ""
        echo -e "${BOLD}$prompt_text${NC}"
        echo ""

        local count=1
        local max_id
        max_id=$(echo "$options_json" | jq '.[-1].id' | tr -d '"')
        
        for option in $(echo "$options_json" | jq -r '.[] | @base64'); do
            local id label
            id=$(echo "$option" | base64 -d | jq -r '.id')
            label=$(echo "$option" | base64 -d | jq -r '.name')
            local desc
            desc=$(echo "$option" | base64 -d | jq -r '.desc // empty')
            echo "   [$id] $label${desc:+ - $desc}"
        done

        if [[ "$allow_back" == "true" ]]; then
            echo "   [0] 返回上一级"
            max_id=0
        fi

        echo ""
        echo -n "   请回复编号 > "
        read_input -r

        if [[ -z "$REPLY" ]]; then
            echo -e "${ERROR}⚠️ 请输入有效选项${NC}"
            continue
        fi

        if [[ "$REPLY" == "0" ]] && [[ "$allow_back" == "true" ]]; then
            return 1
        fi

        if [[ "$REPLY" =~ ^[0-9]+$ ]] && [[ "$REPLY" -ge 0 ]] && [[ "$REPLY" -le $max_id ]]; then
            local selected
            selected=$(echo "$options_json" | jq -r ".[] | select(.id == \"$REPLY\") | .value")
            if [[ -n "$selected" ]]; then
                eval "$var_name=\$selected"
                local selected_name
                selected_name=$(echo "$options_json" | jq -r ".[] | select(.id == \"$REPLY\") | .name")
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
    
    # 检查必填字段
    [[ -z "$AGENT_NAME" ]] && missing_fields+=("AGENT_NAME")
    [[ -z "$AGENT_EMOJI" ]] && missing_fields+=("AGENT_EMOJI")
    [[ -z "$MODEL" ]] && missing_fields+=("MODEL")
    [[ -z "$CHANNEL_TYPE" ]] && missing_fields+=("CHANNEL_TYPE")
    
    # 根据通道类型检查条件必填字段
    case "$CHANNEL_TYPE" in
        feishu)
            [[ -z "$FEISHU_ACCOUNT" ]] && missing_fields+=("FEISHU_ACCOUNT")
            [[ -z "$FEISHU_APP_ID" ]] && missing_fields+=("FEISHU_APP_ID")
            [[ -z "$FEISHU_APP_SECRET" ]] && missing_fields+=("FEISHU_APP_SECRET")
            ;;
        telegram)
            [[ -z "$TELEGRAM_TOKEN" ]] && missing_fields+=("TELEGRAM_TOKEN")
            ;;
        discord)
            [[ -z "$DISCORD_TOKEN" ]] && missing_fields+=("DISCORD_TOKEN")
            ;;
        slack)
            [[ -z "$SLACK_TOKEN" ]] && missing_fields+=("SLACK_TOKEN")
            ;;
    esac
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        echo -e "${ERROR}❌ 静默模式缺少必要参数:${NC}"
        for field in "${missing_fields[@]}"; do
            echo "   - $field"
        done
        echo ""
        echo "使用 --silent 模式需要设置以下环境变量："
        show_help
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

    # 步骤 2: 选择模型（两级菜单）
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 2: 选择模型${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # 第一级：选择厂商
    local model_groups
    model_groups=$(cat << 'EOF'
[
  {"id":1,"name":"MiniMax","desc":"高性价比，国内访问快"},
  {"id":2,"name":"Anthropic","desc":"Claude 系列"},
  {"id":3,"name":"OpenAI","desc":"GPT 系列"},
  {"id":4,"name":"Moonshot","desc":"Kimi 系列"},
  {"id":5,"name":"开源模型","desc":"DeepSeek / Qwen / Llama"},
  {"id":6,"name":"Venice","desc":"隐私优先"},
  {"id":7,"name":"聚合路由","desc":"OpenRouter 等"},
  {"id":8,"name":"本地部署","desc":"Ollama / vLLM"},
  {"id":9,"name":"其他","desc":"NVIDIA / GLM 等"}
]
EOF
    )
    
    prompt_choice "请选择模型厂商" "$model_groups" "SELECTED_GROUP" false
    local group_id="$SELECTED_GROUP"
    
    # 第二级：选择具体模型
    local model_options
    model_options=$(cat << EOF
[
  {"id":"1.1","value":"minimax/MiniMax-M2.5","name":"MiniMax M2.5","desc":"200k上下文"},
  {"id":"1.2","value":"minimax/MiniMax-M2.5-highspeed","name":"M2.5 高速版","desc":"更快响应"},
  {"id":"1.3","value":"minimax/MiniMax-M2.5-Lightning","name":"M2.5 闪电版","desc":"极速"},
  {"id":"1.4","value":"minimax/MiniMax-VL-01","name":"VL-01","desc":"支持视觉"},
  {"id":"2.1","value":"anthropic/claude-opus-4-6","name":"Claude Opus 4.6","desc":"最强推理"},
  {"id":"2.2","value":"anthropic/claude-sonnet-4-6","name":"Claude Sonnet 4.6","desc":"平衡性能"},
  {"id":"2.3","value":"anthropic/claude-haiku-4-6","name":"Claude Haiku 4.6","desc":"极速轻量"},
  {"id":"3.1","value":"openai/gpt-5.4","name":"GPT-5.4","desc":"1M上下文"},
  {"id":"3.2","value":"openai/gpt-5.4-pro","name":"GPT-5.4 Pro","desc":"Pro版"},
  {"id":"3.3","value":"openai/o3","name":"O3","desc":"深度推理"},
  {"id":"3.4","value":"openai/o3-mini","name":"O3 Mini","desc":"Mini版"},
  {"id":"4.1","value":"moonshot/kimi-k2.5","name":"Kimi K2.5","desc":"256k上下文"},
  {"id":"4.2","value":"moonshot/kimi-k2-thinking","name":"Kimi K2 Thinking","desc":"推理版"},
  {"id":"4.3","value":"kimi-coding/k2p5","name":"Kimi Coding","desc":"编程专用"},
  {"id":"5.1","value":"huggingface/deepseek-ai/DeepSeek-R1","name":"DeepSeek R1","desc":"推理强"},
  {"id":"5.2","value":"huggingface/Qwen/Qwen3-8B","name":"Qwen3 8B","desc":"阿里开源"},
  {"id":"5.3","value":"huggingface/meta-llama/Llama-3.3-70B-Instruct","name":"Llama 3.3 70B","desc":"Meta开源"},
  {"id":"5.4","value":"zai/glm-5","name":"GLM-5","desc":"智谱AI"},
  {"id":"6.1","value":"venice/llama-3.3-70b","name":"Venice Llama","desc":"匿名化"},
  {"id":"7.1","value":"openrouter/anthropic/claude-sonnet-4","name":"OpenRouter","desc":"多平台"},
  {"id":"8.1","value":"ollama/qwen2.5","name":"Ollama Qwen","desc":"本地"},
  {"id":"9.1","value":"nvidia/nemotron-70b","name":"NVIDIA","desc":"英伟达"}
]
EOF
    )
    
    # 过滤当前厂商的模型
    local filtered_models
    filtered_models=$(echo "$model_options" | jq "[.[] | select(.id | startswith(\"$group_id\"))]")
    
    prompt_choice "请选择具体模型" "$filtered_models" "MODEL" true
    
    # 如果返回（选择0），重新选择厂商
    if [[ $? -ne 0 ]]; then
        install_interactive
        return
    fi

    # 步骤 3: 选择通道
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 3: 选择通信通道${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local channels
    channels=$(cat << 'EOF'
[
  {"id":1,"value":"feishu","name":"飞书","desc":"需要 App ID + App Secret"},
  {"id":2,"value":"telegram","name":"Telegram","desc":"需要 Bot Token"},
  {"id":3,"value":"discord","name":"Discord","desc":"需要 Bot Token"},
  {"id":4,"value":"slack","name":"Slack","desc":"需要 Bot Token"},
  {"id":5,"value":"skip","name":"跳过","desc":"稍后手动配置"}
]
EOF
    )
    prompt_choice "请选择通信通道" "$channels" "CHANNEL_TYPE" false

    # 根据通道类型追问凭据
    case "$CHANNEL_TYPE" in
        feishu)
            echo ""
            echo -e "${BOLD}🔐 飞书配置${NC}"
            echo ""
            echo "   App ID 和 App Secret 获取地址："
            echo "   https://open.feishu.cn → 你的应用 → 凭证与基础信息"
            echo ""
            prompt "飞书账号名（例如 clawgrow）" "$AGENT_ID" "FEISHU_ACCOUNT"
            prompt "飞书 App ID" "" "FEISHU_APP_ID"
            prompt "飞书 App Secret" "" "FEISHU_APP_SECRET"
            ;;
        telegram)
            prompt "Telegram Bot Token" "" "TELEGRAM_TOKEN"
            ;;
        discord)
            prompt "Discord Bot Token" "" "DISCORD_TOKEN"
            ;;
        slack)
            prompt "Slack Bot Token" "" "SLACK_TOKEN"
            ;;
    esac

    # 步骤 4: 确认安装
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

    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        echo "   自动确认模式，跳过确认步骤"
    else
        local confirm
        echo -n "   确认安装? [Y/n] > "
        read_input -r
        confirm=${REPLY:-y}

        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
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

    # 1. 创建 Agent
    echo "   [1/4] 创建 Agent..."
    local cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"

    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
            cmd="$cmd --bind feishu:$FEISHU_ACCOUNT"
        else
            cmd="$cmd --bind $CHANNEL_TYPE"
        fi
    fi

    echo "   执行: $cmd"
    if ! eval $cmd 2>/dev/null; then
        # 尝试不绑定通道创建
        cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"
        echo "   重试: $cmd"
        eval $cmd || {
            echo -e "${ERROR}❌ openclaw agents add 失败${NC}"
            exit 1
        }
    fi
    echo "   ✓ Agent 创建成功"

    # 2. 更新配置
    echo ""
    echo "   [2/4] 更新配置文件..."
    update_openclaw_json

    # 3. 安装 Skills
    echo ""
    echo "   [3/4] Skills 安装..."
    install_skills

    # 4. 完成
    echo ""
    echo -e "${SUCCESS}✓ 安装完成！${NC}"
    echo ""
    echo "请运行以下命令重启 Gateway："
    echo "   openclaw gateway restart"
    echo ""
    echo "然后就可以通过 $CHANNEL_TYPE 跟 $AGENT_NAME 聊天了！"
}

# ---------- 更新配置 ----------
update_openclaw_json() {
    local json_file="$HOME/.openclaw/openclaw.json"
    
    # 添加到 agentToAgent.allow
    if [[ -f "$json_file" ]]; then
        if ! jq -e --arg agent "$AGENT_ID" '.tools.agentToAgent.allow | index($agent)' "$json_file" >/dev/null 2>&1; then
            jq --arg agent "$AGENT_ID" '.tools.agentToAgent.allow += [$agent]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
            echo "   ✓ 已添加到 agentToAgent.allow"
        fi
        
        # 添加 binding
        if [[ "$CHANNEL_TYPE" != "skip" ]]; then
            local account_id="${FEISHU_ACCOUNT:-$AGENT_ID}"
            local binding_json="{\"agentId\":\"$AGENT_ID\",\"match\":{\"channel\":\"$CHANNEL_TYPE\",\"accountId\":\"$account_id\"}}"
            jq --argjson binding "$binding_json" '.bindings += [$binding]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
            echo "   ✓ 已添加 binding: $CHANNEL_TYPE:$account_id"
        fi
    fi
}

# ---------- 安装 Skills ----------
install_skills() {
    local workspace="~/.openclaw/workspace-$AGENT_ID"
    mkdir -p "$workspace/skills"
    
    # 创建 skills-auto-discovery 目录
    mkdir -p "$workspace/skills/skills-auto-discovery"
    
    # 下载 SKILL.md
    if curl -fsSL "https://raw.githubusercontent.com/delichain/Claw-Grow/main/skills/skills-auto-discovery/SKILL.md" -o "$workspace/skills/skills-auto-discovery/SKILL.md" 2>/dev/null; then
        echo "   ✓ Skills 自动发现已安装"
    else
        echo "   ⚠️ Skills 下载失败，跳过"
    fi
}

# ---------- 主入口 ----------
main() {
    detect_tty
    
    # 解析参数
    parse_args "$@"
    
    # Agent 模式：无 tty 且非静默模式 → 输出结构化清单
    if [[ "$INTERACTIVE_MODE" == "false" ]] && [[ "$SILENT_MODE" == "false" ]]; then
        print_agent_checklist
        exit 0
    fi
    
    # 静默模式：验证参数并执行
    if [[ "$SILENT_MODE" == "true" ]]; then
        validate_silent_mode
        execute_install
        exit 0
    fi
    
    # 交互模式
    install_interactive
}

main "$@"
