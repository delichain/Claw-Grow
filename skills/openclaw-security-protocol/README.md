# 🛡️ OpenClaw Security Protocol Skill

OpenClaw 安全协议的标准化 Skill，包含完整的事前-事中-事后安全架构。

## 功能

- **能力边界**：明确拒绝的操作清单
- **安全红线**：破坏性操作、认证篡改、外发敏感数据等
- **黄线命令**：需要当日记录的操作
- **Skill 安装审计**：安装前全文本排查流程
- **权限收窄**：核心文件权限保护
- **哈希基线**：配置文件完整性验证
- **每晚巡检**：13 项核心指标自动检测
- **大脑灾备**：GitHub 私有仓库自动备份

## 使用方式

该 Skill 主要作为**知识库**使用，无需直接调用。Agent 在执行操作时自动参考本协议的安全规则。

## 快速命令

```bash
# 生成配置哈希基线
sha256sum $OC/openclaw.json > $OC/.config-baseline.sha256

# 验证配置完整性
sha256sum -c $OC/.config-baseline.sha256

# 修复权限
chmod 600 $OC/openclaw.json

# 锁定巡检脚本
sudo chattr +i $OC/workspace/scripts/nightly-security-audit.sh
```

## 巡检指标

1. OpenClaw 安全审计
2. 进程与网络审计
3. 敏感目录变更
4. 系统定时任务
5. OpenClaw Cron Jobs
6. 登录与 SSH
7. 关键文件完整性
8. 黄线操作交叉验证
9. 磁盘使用
10. Gateway 环境变量
11. 明文私钥/凭证泄露扫描
12. Skill/MCP 完整性
13. 大脑灾备自动同步

---
**版本**: 1.0 | **更新**: 2026-03-10
