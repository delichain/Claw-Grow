# TOOLS.md - Agent 技能工具箱

本 Agent 内置以下技能，按功能分类：

---

## 🔍 搜索 & 发现

| Skill | 用途 |
|-------|------|
| **web_search** | 搜索通用网页内容、新闻、资料 |
| **tavily** | AI 优化搜索结果，web_search 的增强版 |
| **find-skills** | 专门搜索可用的 Skill / 工具包 |

---

## 📦 获取 & 安装

| Skill | 用途 |
|-------|------|
| **github** | 从 GitHub 拉取代码、仓库、README |
| **clawhub** | 从 ClawhubAI 平台获取 OpenClaw 专属 Skill |

---

## 🤝 协作 & 执行

| Skill | 用途 |
|-------|------|
| **agent-reach** | 需要调用另一个 Agent 协作完成任务 |

---

## 🧠 创造 & 进化

| Skill | 用途 |
|-------|------|
| **skill-creator** | 现有 Skill 不够用，需要从零生成一个新 Skill |
| **self-improvement** | 分析自身能力缺口，制定成长方向，触发整个成长周期 |

---

---

## 🔐 安全
| Skill | 用途 |
|-------|------|
| **openclaw-security-protocol** | agent的安全准则，一切行动都要经过这个文档，一切都以这个文档内的标准行动 |


## 搜索分层策略

### L1 快速搜索 - Exa 语义搜索
- **用途**：秒级，用于事实查询、单点问题
- **工具**：Exa 语义搜索（Tavily 备用）
- **触发**：一句话能答的问题

### L2 平台抓取 - Agent Reach 上游工具
- **用途**：指定平台或 URL 的内容提取
- **工具**：xreach (Twitter) / yt-dlp (YouTube/B站) / gh (GitHub) / Jina Reader (任意网页) / mcporter (小红书、抖音等)
- **触发**：有 URL 或指定平台

### L3 深度调研 - Minimax2.5 + BrowserWing
- **用途**：多源对比、"帮我调研"、复杂主题
- **工具组合**：
  - **BrowserWing**：打开多标签页并行抓取关键源
  - **Tavily**：全网语义搜索补充
  - **Agent Reach**：特定平台内容（Twitter，B站、YouTube 等）
- **流程**：任务指派给 Minimax2.5 → BrowserWing 多源抓取 → Tavily 搜索补充 → 深度推理 → 生成详细文字 + 可视化报表
- **要求**：必须注明来源
- **原则**：平台内容优先原生工具

### 选择规则
- **有 URL/指定平台** → L2
- **一句话能答** → L1
- **多源对比/"帮我调研"** → L3
- **默认 L1 起步**，不够再升级

---

## Claw-Grow 六阶段能力映射

| Phase | 技能 |
|-------|------|
| Phase 1 记忆分析 | self-improvement |
| Phase 2 技能搜猎 | find-skills → github / clawhub → web_search / tavily（兜底） |
| Phase 4 多 Agent 协作 | agent-reach |
| Phase 6 自我创作 | skill-creator |
