# 安装 brd-to-feature skill

brd-to-feature 是一个**纯 skill 形态**的工作流 skill，可以装到任何支持 Skill 工具 + `context:fork` 的 coding agent 里（Claude Code / Trae / Cursor / Codex 等）。本文档给出按 agent 分类的安装指引，遵循**总原则**：

> **agent 能装的绝不让用户手装，agent 装不了的明确告诉你怎么做。**

---

## 总原则再细化

| 谁做 | 内容 |
|------|------|
| ✅ **你（一次性的拷贝 + 配置）** | 把 skill 文件拷贝到 agent 的 skills 目录；把 MCP server 加到 agent 的 MCP 配置 |
| ✅ **agent（每次 btf-init 时）** | 自动装 markitdown、检测 Node.js、写入 MCP 配置片段（征得你同意后）、**用 `AskUserQuestion` 问你要 token 并保存进配置**、体检 |
| 🛑 **只能你** | 登录 Figma **生成** token（生成后粘给 agent 即可，保存交给 agent）、下载微信开发者工具 GUI、装 Chrome 浏览器扩展 |

意味着：**首次安装是一次性的体力活**（拷贝 + 配 MCP server 占位）；**之后每次跑 btf-init 时 agent 自己处理大部分**（装 markitdown、配 MCP token 段、检测环境）。

---

## 通用目录约定

不管装到哪个 agent，目录结构都是这样：

```
<agent 的 skills 根目录>/
└── brd-to-feature/                  ← 整个 skill 目录
    ├── SKILL.md
    ├── scripts/
    │   ├── btf-init.sh
    │   └── ensure_markitdown.sh
    ├── references/
    │   ├── guardrails.md
    │   ├── figma.md
    │   ├── web-testing.md
    │   └── miniprogram-testing.md
    ├── assets/                       ← 文档模板（agent 引用）
    ├── commands/
    │   └── btf-init.md              ← 斜杠命令定义（可选）
    └── skills/                       ← 内部 fork 子 skill（agent 自动用）
        ├── btf-explore-project/SKILL.md
        ├── btf-code-review/SKILL.md
        └── btf-run-tests/SKILL.md
```

外加一个 MCP 配置片段（由 btf-init 时 agent 自动写入；首次安装如果你愿意也可以自己先粘好）。

---

## Claude Code

最完整支持。

### 1. 拷贝 skill（一次性）

**全局级（默认 · 推荐）**——装一次，所有项目里都能 `/btf`，不用每个项目重拷：

```bash
mkdir -p ~/.claude/skills ~/.claude/commands
cp -R brd-to-feature ~/.claude/skills/
cp brd-to-feature/commands/btf-init.md ~/.claude/commands/
```

**项目级（可选）**——只在需要团队共享、把 skill 随项目一起提交时才用：

```bash
cp -R brd-to-feature <你的项目根>/.claude/skills/
cp brd-to-feature/commands/btf-init.md <你的项目根>/.claude/commands/
```

> 📌 **默认走全局**。本 skill 是个人通用工作流，不绑定某个项目；全局安装后在任意项目 `/btf` 即可。项目级仅用于团队想把它随仓库分发的场景。两者同时存在时，Claude Code 以项目级覆盖全局。

### 2. 加 MCP server（一次性，或交给 btf-init 时 agent 自动加）

默认编辑**全局** `~/.claude/mcp.json`（与上面全局安装对应；项目级安装才用 `<项目根>/.mcp.json`），加入：

```jsonc
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "${FIGMA_API_KEY}" }
    },
    "weapp-dev": {
      "command": "npx",
      "args": ["-y", "@yfme/weapp-dev-mcp"],
      "env": { "WEAPP_WS_ENDPOINT": "${WEAPP_WS_ENDPOINT}" }
    }
  }
}
```

> 💡 **这一步也可以跳过**：btf-init 时 agent 会自动写。前提是你授权 agent 改 `~/.claude/mcp.json`。
> 💡 **token 不用你手填**：上面 `FIGMA_API_KEY` 的 `${...}` 只是占位——btf-init 时 agent 会用 `AskUserQuestion` 问你要真实 token 并直接写进 `env`（见本文末「通用 MCP server 片段」的说明）。`weapp-dev` 端点默认 `ws://localhost:9420`。

### 3. 验证

打开 Claude Code，说 "btf-init"。agent 会跑 `scripts/btf-init.sh` 检测并引导你补环境。

### 4. 高级：fork 子 skill 支持

`context: fork` + `user-invocable: false` 是 Claude Code 原生支持的——意味着 `btf-explore-project` / `btf-code-review` / `btf-run-tests` 三个子 skill 能正常在隔离上下文里跑，不需要额外配置。

---

## Trae

### 1. 找到 skills 目录

Trae 的 skill 目录位置随版本变化。在 Trae 设置里搜 "skill" 或 "custom skill" 通常能找到。**如果你不确定路径**：

```bash
# macOS / Linux 常见位置
ls -d ~/.trae/skills 2>/dev/null
ls -d ~/Library/Application\ Support/Trae/skills 2>/dev/null
# Windows 常见位置
ls "%APPDATA%/Trae/skills" 2>/dev/null
```

或者直接在 Trae 里问："你的 skill 目录在哪？"

### 2. 拷贝 skill

把整个 `brd-to-feature/` 目录拷到 Trae 的 skills 根目录下：

```bash
cp -R brd-to-feature <上面找到的路径>/
```

### 3. 斜杠命令（可选）

Trae 是否支持自定义斜杠命令视版本而定。如果支持：

```bash
mkdir -p <Trae 的 commands 目录>
cp brd-to-feature/commands/btf-init.md <Trae 的 commands 目录>/
```

如果不支持：直接跟 agent 说 "btf-init" 也能触发（SKILL.md 里有对应的描述匹配）。

### 4. MCP 配置

Trae 的 MCP 配置位置也在它的设置里。**如果你愿意手动加**：

```jsonc
{
  "mcpServers": {
    "figma": { /* 同 Claude Code */ },
    "weapp-dev": { /* 同 Claude Code */ }
  }
}
```

**或者跳过**，让 btf-init 时的 agent 自己加（如果 Trae 允许 agent 写自己的配置）。

### 5. ⚠️ 关于 `context: fork`

Trae **是否支持** `Skill` 工具的 `context:fork` 参数，取决于其版本：
- ✅ 支持：三个子 skill 正常在隔离上下文跑，主上下文不被污染。
- ❌ 不支持：agent 会回退到主上下文内联执行——意味着阶段 1c/4/6 会把整个项目文件塞进主上下文，可能爆 token。SKILL.md 已经写了"退化为在主上下文里按 6 点自行通读项目即可"。

**如何验证**：打开 Trae，问 "请用 btf-explore-project 子 skill 通读 /tmp"，看是否报错。

---

## Cursor

### 1. 找到 skills 目录

Cursor 的 skill/规则系统近年在演化，不同版本路径不同。

```bash
ls -d ~/.cursor/skills 2>/dev/null
ls -d ~/Library/Application\ Support/Cursor/skills 2>/dev/null
ls "%APPDATA%/Cursor/skills" 2>/dev/null
```

或者 Cursor 设置 → Rules / Skills 找。

### 2. 拷贝 skill

```bash
cp -R brd-to-feature <Cursor 的 skills 根目录>/
```

### 3. ⚠️ `context: fork` 支持

Cursor **部分版本**支持 `Skill` 工具，但 `context:fork` 不一定支持。验证方式同上（开个测试项目问 agent 调子 skill）。

如果不支持，子任务会退化为内联——Cursor 上下文比较大，还能撑得住。

### 4. MCP 配置

Cursor 的 MCP 配置在设置里，或 `~/.cursor/mcp.json`。**推荐手动加**（Cursor 的 MCP 配置 UI 已经做得很友好）：

```jsonc
{
  "mcpServers": {
    "figma": { /* 同 Claude Code */ },
    "weapp-dev": { /* 同 Claude Code */ }
  }
}
```

---

## 通用 MCP server 片段（拷贝用）

不管哪个 agent，MCP server 配置都是这两块：

```jsonc
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "figd_你的真实token" }
    },
    "weapp-dev": {
      "command": "npx",
      "args": ["-y", "@yfme/weapp-dev-mcp"],
      "env": { "WEAPP_WS_ENDPOINT": "ws://localhost:9420" }
    }
  }
}
```

> **token 不用你手动填**：跑 `btf-init` 时，agent 会用 `AskUserQuestion` 向你索取 Figma token（附获取方式），你填进去后 **agent 直接把 token 写进上面的 `env` 字段**——你不需要 `export` 环境变量、也不用手编这个文件。`weapp-dev` 的端点默认填 `ws://localhost:9420`，连通性留到测小程序时再校验。
>
> ⚠️ token 写进配置文件后是**明文**：别把该文件提交进 git，建议加进 `.gitignore`。

---

## 验证清单（不管哪个 agent）

跑完 `btf-init` 后应该看到：

- [ ] `bash scripts/btf-init.sh` 跑通，输出 `=== 检测完成 ===`
- [ ] （如按设计稿开发）agent 已用 `AskUserQuestion` 问你要 Figma token，你已填、agent 已把它写进 MCP 配置 `env`
- [ ] agent 的工具列表里有 `figma` / `mp_*` 工具（取决于本项目用哪个）
- [ ] （如测小程序）agent 已把 `mcp__weapp-dev__*` 工具加进**当前 agent 的免确认配置**（Claude Code = 全局 `~/.claude/settings.local.json` 的 `permissions.allow`；其他 agent 按其文档）——免确认，避免调用弹窗打断连接
- [ ] （如测小程序）微信开发者工具的 9420 端点连通性——**不在此校验**，留到阶段 6 打开小程序时再验
- [ ] （如测 Web）Chrome 扩展已装、`mcp__*Chrome*` 工具可见
- [ ] agent 给的「环境健康度快照」里所有要用的工具都是 ✅ / 🟢（token 已存）/ 🟠（配置已写入）

---

## 升级

升级 skill 就是重新覆盖目录：

```bash
cp -R brd-to-feature <skills 目录>/    # 覆盖即可
```

MCP 配置通常不变（除非 server 实现改了参数）。