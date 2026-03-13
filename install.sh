#!/bin/bash
set -uo pipefail

# =============================================================================
# Claw Grow - Agent 安装向导
# 底层调用 openclaw agents add 官方命令
# =============================================================================

readonly SCRIPT_VERSION="1.2.0"

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
FEISHU_APP_ID=""
FEISHU_APP_SECRET=""

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
  {"label": "其他模型...", "value": "custom"}
]
EOF
    )
    prompt_choice "请选择模型" "$models_json" "MODEL"

    if [[ "$MODEL" == "custom" ]]; then
        prompt "请输入模型ID" "minimax/MiniMax-M2.5" "MODEL"
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

    if [[ "$CHANNEL_TYPE" == "feishu" ]]; then
        prompt "请输入飞书账号名" "$AGENT_ID" "FEISHU_ACCOUNT"
        prompt "请输入飞书 App ID" "" "FEISHU_APP_ID"
        prompt "请输入飞书 App Secret" "" "FEISHU_APP_SECRET"
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

    # 1. 调用 openclaw agents add
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
        echo -e "${ERROR}安装失败${NC}"
        exit 1
    fi

    # 2. 更新 openclaw.json
    update_openclaw_json

    # 3. 克隆 GitHub 上的身份文件模板
    echo "   克隆身份文件模板..."
    local workspace="~/.openclaw/workspace-$AGENT_ID"
    
    # 临时克隆仓库获取模板文件
    local temp_dir=$(mktemp -d)
    if git clone --depth 1 https://github.com/delichain/Claw-Grow.git "$temp_dir" 2>/dev/null; then
        # 复制模板文件（如果存在）
        [[ -f "$temp_dir/SOUL.md" ]] && cp "$temp_dir/SOUL.md" "$workspace/SOUL.md"
        [[ -f "$temp_dir/USER.md" ]] && cp "$temp_dir/USER.md" "$workspace/USER.md"
        [[ -f "$temp_dir/AGENTS.md" ]] && cp "$temp_dir/AGENTS.md" "$workspace/AGENTS.md"
        [[ -f "$temp_dir/TOOLS.md" ]] && cp "$temp_dir/TOOLS.md" "$workspace/TOOLS.md"
        [[ -f "$temp_dir/HEARTBEAT.md" ]] && cp "$temp_dir/HEARTBEAT.md" "$workspace/HEARTBEAT.md"
        
        # 更新 USER.md 中的变量占位符
        if [[ -f "$workspace/USER.md" ]]; then
            sed -i "" "s/{{AGENT_NAME}}/$AGENT_NAME/g" "$workspace/USER.md" 2>/dev/null || true
            sed -i "" "s/{{AGENT_EMOJI}}/$AGENT_EMOJI/g" "$workspace/USER.md" 2>/dev/null || true
        fi
        
        # 复制 skills 文件夹（如果存在）
        if [[ -d "$temp_dir/skills" ]]; then
            cp -r "$temp_dir/skills" "$workspace/skills"
            echo "   ✓ 已下载 skills 文件夹"
        fi
        
        rm -rf "$temp_dir"
        echo "   ✓ 已下载身份文件模板"
    else
        echo "   ⚠️ 无法克隆模板，跳过"
    fi

    # 4. 提示重启
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
    
    echo "   更新 openclaw.json..."
    
    # 1. 更新 tools.agentToAgent.allow
    if [[ -f "$json_file" ]]; then
        # 添加 agent 到 agentToAgent.allow 列表
        local current_allow
        current_allow=$(jq -r '.tools.agentToAgent.allow[]' "$json_file" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        # 检查是否已存在
        if ! echo "$current_allow" | grep -q "$agent_id"; then
            jq --arg agent "$agent_id" '.tools.agentToAgent.allow += [$agent]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
            echo "   ✓ 已添加到 tools.agentToAgent.allow"
        fi
    fi
    
    # 2. 更新 channels (如果是飞书)
    if [[ "$CHANNEL_TYPE" == "feishu" ]] && [[ -n "$FEISHU_APP_ID" ]] && [[ -n "$FEISHU_APP_SECRET" ]]; then
        local channel_json=$(cat << EOF
{
  "appId": "$FEISHU_APP_ID",
  "appSecret": "$FEISHU_APP_SECRET",
  "groups": {}
}
EOF
        )
        jq --arg account "$FEISHU_ACCOUNT" --argjson data "$channel_json" '.channels.feishu.accounts[$account] = $data' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
        echo "   ✓ 已添加飞书账号: $FEISHU_ACCOUNT"
    fi
    
    # 3. 更新 bindings (如果选择了通道)
    if [[ "$CHANNEL_TYPE" != "skip" ]]; then
        local binding_json=$(cat << EOF
{
  "agentId": "$agent_id",
  "match": {
    "channel": "$CHANNEL_TYPE",
    "accountId": "$FEISHU_ACCOUNT"
  }
}
EOF
        )
        jq --argjson binding "$binding_json" '.bindings += [$binding]' "$json_file" > tmp_$$.json && mv tmp_$$.json "$json_file"
        echo "   ✓ 已添加 binding: $CHANNEL_TYPE:$FEISHU_ACCOUNT"
    fi
}

# ---------- 主入口 ----------
main() {
    parse_args "$@"
    install
}

main "$@"
