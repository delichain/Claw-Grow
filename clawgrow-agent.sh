#!/bin/bash
set -uo pipefail

# =============================================================================
# Claw Grow - Agent 安装向导
# 复用官方 openclaw agents add 命令
# =============================================================================

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="clawgrow-agent"

# ---------- 颜色 ----------
BOLD='\033[1m'
SUCCESS='\033[38;2;0;229;204m'
ERROR='\033[38;2;230;57;70m'
WARN='\033[38;2;255;176;32m'
NC='\033[0m'

# ---------- 全局变量 ----------
AGENT_ID="clawgrow"
AGENT_NAME=""
AGENT_EMOJI=""
MODEL=""
CHANNEL_TYPE=""
FEISHU_ACCOUNT=""

# ---------- 解析参数 ----------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_MODE=true ;;
            -h|--help) show_help; exit 0 ;;
            *) echo -e "${ERROR}未知选项: $1${NC}"; show_help; exit 1 ;;
        esac
        shift
    done
}

show_help() {
    echo "Claw Grow Agent 安装向导 v${SCRIPT_VERSION}"
    echo ""
    echo "用法: $(basename "$0") [选项]"
    echo ""
    echo "选项:"
    echo "  -y, --yes  自动确认"
    echo "  -h, --help 显示帮助"
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
    read -r

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

    echo ""
    echo -e "${BOLD}📝 $prompt_text${NC}"
    echo ""

    local count=1
    for option in $(echo "$options_json" | jq -r '.[] | @base64'); do
        local label
        label=$(echo "$option" | base64 -d | jq -r '.label')
        echo "   [$count] $label"
        ((count++))
    done

    echo ""
    echo -n "   请输入选项编号 > "
    read -r

    if [[ "$REPLY" =~ ^[0-9]+$ ]] && [[ "$REPLY" -ge 1 ]] && [[ "$REPLY" -le $count-1 ]]; then
        local selected
        selected=$(echo "$options_json" | jq -r ".[$((REPLY-1))].value")
        eval "$var_name=\$selected"
        echo -e "   ${SUCCESS}✓ 已选择: $(echo "$options_json" | jq -r ".[$((REPLY-1))].label")${NC}"
    else
        echo -e "${ERROR}无效选择${NC}"
        eval "$var_name=$(echo "$options_json" | jq -r '.[0].value')"
    fi
}

# ---------- 安装流程 ----------
install() {
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
  {"label": "MiniMax M2.5 (200k上下文)", "value": "minimax/MiniMax-M2.5"},
  {"label": "MiniMax M2.5 高速版", "value": "minimax/MiniMax-M2.5-highspeed"},
  {"label": "OpenAI GPT-5.4", "value": "openai/gpt-5.4"},
  {"label": "Anthropic Claude Sonnet 4.6", "value": "anthropic/claude-sonnet-4-6"},
  {"label": "Moonshot Kimi K2.5", "value": "moonshot/kimi-k2.5"},
  {"label": "自定义模型...", "value": "custom"}
]
EOF
    )
    prompt_choice "请选择模型" "$models_json" "MODEL"

    if [[ "$MODEL" == "custom" ]]; then
        prompt "请输入模型ID" "minimax/MiniMax-M2.5" "MODEL"
    fi

    # 模型 API 配置
    echo ""
    echo -e "${BOLD}📡 模型 API 配置${NC}"
    echo ""
    echo "   [1] 使用当前配置 (默认)"
    echo "   [2] 粘贴新的 API Key"
    echo ""
    echo -n "   请选择 > "
    read -r

    if [[ "$REPLY" == "2" ]]; then
        prompt "请粘贴 API Key" "" "CUSTOM_API_KEY"
        # TODO: 这里可以添加更新 auth-profiles.json 的逻辑
        echo "   ✓ API Key 已记录"
    else
        echo "   ✓ 使用当前配置"
    fi

    # 步骤 3: 选择通道
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}步骤 3: 选择通信通道${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local channels_json
    channels_json=$(cat << 'EOF'
[
  {"label": "飞书 (Feishu)", "value": "feishu"},
  {"label": "Telegram", "value": "telegram"},
  {"label": "Discord", "value": "discord"},
  {"label": "跳过", "value": "skip"}
]
EOF
    )
    prompt_choice "请选择通信通道" "$channels_json" "CHANNEL_TYPE"

    # 显示通道配置代码
    if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
        prompt "请输入飞书账号名" "$AGENT_ID" "FEISHU_ACCOUNT"
        
        echo ""
        echo -e "${BOLD}📋 飞书配置代码${NC}"
        echo ""
        echo "   你需要准备以下信息："
        echo "   - appId: 飞书应用 ID"
        echo "   - appSecret: 飞书应用密钥"
        echo ""
        echo "   获取方式："
        echo "   1. 打开 https://open.feishu.cn/"
        echo "   2. 创建应用 → 找到应用详情"
        echo "   3. 在'凭证与基础信息'中获取 App ID 和 App Secret"
        echo ""
        prompt "请输入飞书 App ID" "" "FEISHU_APP_ID"
        prompt "请输入飞书 App Secret" "" "FEISHU_APP_SECRET"
        
    elif [[ "$CHANNEL_TYPE" == "telegram" ]]; then
        echo ""
        echo -e "${BOLD}📋 Telegram 配置代码${NC}"
        echo ""
        echo "   你需要准备以下信息："
        echo "   - botToken: Telegram Bot Token"
        echo ""
        echo "   获取方式："
        echo "   1. @BotFather 创建新机器人"
        echo "   2. 获取 Bot Token"
        echo ""
        prompt "请输入 Telegram Bot Token" "" "TELEGRAM_TOKEN"
        
    elif [[ "$CHANNEL_TYPE" == "discord" ]]; then
        echo ""
        echo -e "${BOLD}📋 Discord 配置代码${NC}"
        echo ""
        echo "   你需要准备以下信息："
        echo "   - token: Discord Bot Token"
        echo ""
        echo "   获取方式："
        echo "   1. https://discord.com/developers/applications"
        echo "   2. 创建应用 → Bot → 获取 Token"
        echo ""
        prompt "请输入 Discord Bot Token" "" "DISCORD_TOKEN"
    fi

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

    local confirm
    echo -n "   确认安装? [Y/n] > "
    read -r
    confirm=${REPLY:-y}

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "已取消"
        exit 0
    fi

    # 执行安装
    execute_install
}

execute_install() {
    echo ""
    echo -e "${BOLD}🔧 开始安装...${NC}"
    echo ""

    # 1. 调用 openclaw agents add（官方命令，自动创建 workspace + 身份文件）
    echo "   [1/4] 调用官方命令创建 Agent..."
    local cmd="openclaw agents add $AGENT_ID --workspace ~/.openclaw/workspace-$AGENT_ID --model $MODEL --non-interactive"

    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
            cmd="$cmd --bind feishu:$FEISHU_ACCOUNT"
        else
            cmd="$cmd --bind $CHANNEL_TYPE"
        fi
    fi

    echo "   执行: $cmd"
    eval $cmd

    if [[ $? -ne 0 ]]; then
        echo -e "${ERROR}❌ openclaw agents add 失败${NC}"
        exit 1
    fi
    echo "   ✓ Agent 创建成功"

    # 2. 提示用户登录 channel
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        echo ""
        echo "   [2/4] Channel 登录..."
        echo ""
        echo -e "${WARN}⚠️ 请运行以下命令登录 channel:${NC}"
        echo ""
        echo "   openclaw channels login --channel $CHANNEL_TYPE --account ${FEISHU_ACCOUNT:-$AGENT_ID}"
        echo ""
        echo -e "${WARN}   登录完成后再继续...${NC}"
        echo -n "   按回车继续 > "
        read -r
    fi

    # 3. 更新 openclaw.json（bindings + agentToAgent）
    echo ""
    echo "   [3/4] 更新配置文件..."
    update_openclaw_json

    # 4. 安装 Skills（可选）
    echo ""
    echo "   [4/4] Skills 安装..."
    install_skills

    # 5. 提示重启
    echo ""
    echo -e "${SUCCESS}✓ 安装完成！${NC}"
    echo ""
    echo "请手动执行以下命令重启 Gateway："
    echo "   openclaw gateway restart"
    echo ""
    echo "然后就可以通过 $CHANNEL_TYPE 跟 $AGENT_NAME 聊天了！"
}

# ---------- 更新 openclaw.json ----------
update_openclaw_json() {
    local json_file="$HOME/.openclaw/openclaw.json"
    local agent_id="$AGENT_ID"
    
    # 1. 更新 tools.agentToAgent.allow
    if [[ -f "$json_file" ]]; then
        local current_allow
        current_allow=$(jq -r '.tools.agentToAgent.allow[]' "$json_file" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        if ! echo "$current_allow" | grep -q "$agent_id"; then
            jq --arg agent "$agent_id" '.tools.agentToAgent.allow += [$agent]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
            echo "   ✓ 已添加到 tools.agentToAgent.allow"
        fi
    fi
    
    # 2. 更新 bindings
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        local account_id="${FEISHU_ACCOUNT:-$agent_id}"
        local binding_json=$(cat << EOF
{
  "agentId": "$agent_id",
  "match": {
    "channel": "$CHANNEL_TYPE",
    "accountId": "$account_id"
  }
}
EOF
        )
        jq --argjson binding "$binding_json" '.bindings += [$binding]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
        echo "   ✓ 已添加 binding: $CHANNEL_TYPE:$account_id"
    fi
}

# ---------- 安装 Skills ----------
install_skills() {
    echo ""
    echo -e "${BOLD}📦 可选 Skills 安装${NC}"
    echo ""
    echo "   [1] 安装 Skills 自动发现流程（推荐）"
    echo "   [2] 跳过"
    echo ""
    echo -n "   请选择 > "
    read -r

    case "$REPLY" in
        1)
            local workspace="~/.openclaw/workspace-$AGENT_ID"
            mkdir -p "$workspace/skills"
            
            # 创建 skills-auto-discovery 目录
            mkdir -p "$workspace/skills/skills-auto-discovery"
            
            # 下载 SKILL.md
            if curl -fsSL "https://raw.githubusercontent.com/delichain/Claw-Grow/main/skills/skills-auto-discovery/SKILL.md" -o "$workspace/skills/skills-auto-discovery/SKILL.md" 2>/dev/null; then
                echo "   ✓ Skills 自动发现流程已安装"
            else
                echo "   ⚠️ 无法下载，跳过"
            fi
            ;;
        *)
            echo "   ✓ 跳过"
            ;;
    esac
}

# ---------- 主入口 ----------
main() {
    parse_args "$@"
    install
}

main "$@"
