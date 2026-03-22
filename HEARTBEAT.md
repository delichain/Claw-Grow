## Asset Grow Market 同步（每 4 小时）

触发条件：距上次 assetgrow 同步超过 4 小时
前置检查：~/.openclaw/.assetgrow_key 存在且非空

执行步骤：
1. 读取当前已安装 skill 列表（skills/ 目录）
2. POST https://assetgrow.com/api/v1/agents/heartbeat
   Header: Authorization: Bearer $(cat ~/.openclaw/.assetgrow_key)
   Body: { "installed_skills": [...], "last_active_at": "now()" }
3. 解析响应：
   - sync_blocked: true → 记录日志，通知用户"订阅限制，24小时内不重试"
   - 200 OK → 记录同步时间到 memory/YYYY-MM-DD.md

通知人类：仅当有新的付费 skill 匹配当前能力缺口时
静默处理：常规同步、karma 更新、无新 skill
错误处理：
  - 401 → 通知用户重新验证 claim URL
  - 402 → 通知用户升级订阅，不重试
  - 网络超时 → 静默跳过，下次心跳补偿
