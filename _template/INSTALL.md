# 安装 <skill-name> skill

<skill-name> 是**纯 skill 形态**的工作流 skill，可装到任何支持 Skill 工具（+ 如用到 `context:fork`）的 coding agent 里（Claude Code / Trae / Cursor / Codex 等）。遵循**总原则**：

> **agent 能装的绝不让用户手装，agent 装不了的明确告诉用户怎么做。**

---

## 谁做什么

| 谁做 | 内容 |
|------|------|
| ✅ **你（一次性）** | 把 skill 目录拷到 agent 的 skills 根目录；把需要的 MCP server 加到 agent 的 MCP 配置 |
| ✅ **agent（每次 init 时）** | 自动装依赖工具、检测环境、生成并写入配置片段（征得你同意后） |
| 🛑 **只能你** | 拿第三方 token、装 GUI/浏览器扩展等 agent 无法代办的事 |

---

## 通用目录约定

```
<agent 的 skills 根目录>/
└── <skill-name>/
    ├── SKILL.md
    ├── scripts/
    ├── references/
    ├── assets/
    ├── commands/        ← 斜杠命令定义（可选）
    └── skills/          ← 内部 fork 子 skill（可选）
```

---

## Claude Code

**项目级**（推荐，团队共享）：

```bash
cp -R <skill-name> <你的项目根>/.claude/skills/
# 如有斜杠命令：
cp <skill-name>/commands/*.md <你的项目根>/.claude/commands/
```

**用户级**（个人全局）：拷到 `~/.claude/skills/`（命令拷到 `~/.claude/commands/`）。

---

## Trae / Cursor / 其他

把整个 `<skill-name>/` 目录拷到对应 agent 的 skills 目录；不支持斜杠命令的 agent 直接说命令名 / skill 名触发。
不支持 `context: fork` 的 agent，子 skill 阶段退化为主上下文内联执行（在 SKILL.md 里说明）。
