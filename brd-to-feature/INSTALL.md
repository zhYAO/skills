# 安装 brd-to-feature skill

brd-to-feature 是一个**纯 skill 形态**的工作流 skill，可以装到任何支持 Skill 工具 + `context:fork` 的 coding agent 里（Claude Code / Trae / Cursor / Codex 等）。

> ⚠️ **本文里所有具体路径（`~/.claude/...`）、`/btf` 斜杠命令写法都是「Claude Code 的示例」，不是最终安装步骤。** skill 是跨 agent 的语义层概念——真正要做的是下面那「5 步通用流程」；至于「文件放哪个目录、MCP/免确认配置怎么写、斜杠命令支不支持」，**取决于你用的是哪个 coding agent，以该 agent 自己的文档为准**。下面的 Claude Code / Trae / Cursor 三节只是把这 5 步在各自 agent 上「填了一遍空」，供参照；用别的 agent 就照 5 步流程对号入座。

遵循**总原则**：

> **agent 能装的绝不让用户手装，agent 装不了的明确告诉你怎么做。**

---

## 🧭 通用安装流程（任何 coding agent 都是这 5 步）

不管哪个 agent，安装本质都是这 5 件事。**先理解这 5 步，再去下面找你的 agent 对应的具体路径/写法；找不到你的 agent，就按这 5 步问该 agent 文档自行落地。**

| 步骤 | 做什么 | 因 agent 而异的地方 |
|------|--------|--------------------|
| **1. 放 skill 目录** | 把整个 `brd-to-feature/` 拷到「该 agent 的 skills 根目录」 | 目录位置不同（Claude Code `~/.claude/skills/`、Trae/Cursor 各异）——不确定就查该 agent 文档或直接问它「你的 skill 目录在哪」 |
| **2.（可选）放斜杠命令** | 若该 agent 支持自定义斜杠命令，拷 `commands/*.md` 过去 | 支不支持、放哪都因 agent 而异；不支持就直接对 agent 说「btf-init」「用 btf」靠 description 触发 |
| **3. 配 MCP server** | 把 figma / weapp-dev 两个 MCP server 加进「该 agent 的 MCP 配置」 | 配置文件位置/格式不同；多数 agent 也允许 btf-init 时让 agent 自动写（见下） |
| **4.（测小程序才需要）配工具免确认** | 把 `mcp__weapp-dev__*` 工具加进「该 agent 的工具免确认/自动批准配置」 | Claude Code 是 `settings.local.json` 的 `permissions.allow`；其他 agent 是各自的 auto-approve 开关，**以其文档为准** |
| **5. 验证 + 体检** | 跑 `btf-init` 让 agent 自检环境、问你要 token、补齐缺口 | 触发方式因 agent 而异（斜杠命令或自然语言） |

> 第 3、4 步的「配置文件」大多可以**交给 btf-init 时的 agent 自动写**（前提是该 agent 允许 agent 改自己的配置文件）；写不了/没权限时 btf-init 会给你手动指引（见 `commands/btf-init.md` 的「写入失败 / 无权限兜底」）。
> `context: fork` 是否被支持也因 agent 而异：支持则三个子 skill 在隔离上下文跑；不支持则退化为主上下文内联（见各节说明）。

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

## 示例 A · Claude Code

> 下面是把「5 步通用流程」落到 Claude Code 上的**示例**（最完整支持）。用别的 agent 别照抄路径，对照 5 步换成你 agent 的对应位置。

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

## 示例 B · Trae

> 同样是「5 步通用流程」在 Trae 上的示例；路径随版本变化，以 Trae 文档为准。

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

## 示例 C · Cursor

> 「5 步通用流程」在 Cursor 上的示例；Cursor 的 skill/规则系统在演化，以其当前文档为准。

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

## 其他 coding agent（Codex / 任何没在上面列出的）

上面三节只是示例。**用任何其他 agent，照「5 步通用流程」对号入座即可**，关键是搞清你这个 agent 的四个位置（查它的文档，或直接问 agent 本身）：

1. **skills 根目录在哪** → 把 `brd-to-feature/` 整目录拷进去（第 1 步）。
2. **支不支持自定义斜杠命令、放哪** → 支持就拷 `commands/*.md`；不支持就直接说「btf-init」「用 btf」触发（第 2 步）。
3. **MCP 配置文件在哪、什么格式** → 加 figma / weapp-dev 两个 server，或交给 btf-init 时 agent 自动写（第 3 步）。
4. **工具免确认/自动批准配置在哪**（仅测小程序需要）→ 把 `mcp__weapp-dev__*` 加进去（第 4 步）。

然后跑 `btf-init`（第 5 步），让 agent 自检并补齐。**只要该 agent 支持「Skill 工具」，本 skill 就能用**；`context: fork` 不支持时子 skill 退化为内联执行，功能不受影响、只是更吃主上下文 token。拿不准就把本节这 4 个问题直接抛给你的 agent。

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