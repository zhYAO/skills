---
description: 初始化 brd-to-feature 所需的工具（markitdown / Figma MCP / Chrome MCP / 小程序 MCP / Node.js），不解析任何需求。**用户主动调用**：用 /btf-init 斜杠命令触发，或显式说"btf-init"。不自动触发。
---

# 🔧 btf-init · 工具初始化

> **目标**：把本 skill 跑起来要的工具一次性检测到位，能 agent 自动装的就 agent 装、装不了的给你清晰的人工步骤。
> **边界**：只准备环境，**不解析需求、不开始开发**。正式流程由你下一条消息发起。

## 🎯 总原则

| 谁来装 | 工具 |
|--------|------|
| ✅ **agent 自动装**（征得你同意后） | markitdown、figma / weapp-dev MCP server（写进 MCP 配置）、weapp-dev 工具权限（写进**当前 agent 的免确认配置**——Claude Code 是 `~/.claude/settings.local.json` 的 `permissions.allow`，其他 agent 按其文档） |
| ⚠️ **agent 尝试装，失败再交你** | Node.js（macOS/Linux 包管理器） |
| 🟢 **agent 问你要 token、你填、agent 保存** | Figma token（FIGMA_API_KEY）——agent 用 `AskUserQuestion` 询问并备注获取方式，你填进去后 **agent 直接写进 MCP 配置**，不让你手动设环境变量 |
| 🛑 **只能你来**（GUI / 登录 / 浏览器商店） | 微信开发者工具、生成 Figma token（登录 Figma 那一步）、Chrome 扩展 |

> **token 处理新约定**：凡是 MCP 需要的 token，**agent 主动用 `AskUserQuestion` 向你索取**（每个 token 附上「在哪拿、怎么拿」的备注），你填好后 **agent 负责保存**（写进 agent 的 MCP 配置 `env` 字段），你**不需要**自己 `export` 或编辑配置文件。详见下方 Step 2 第 4 项。

---

## 📍 执行步骤

### Step 1 · 自动体检

```bash
bash <skill 目录>/scripts/btf-init.sh
```

把脚本打印的每项 `[OK]` / `[MISS]` 抄下来，下面会用。

### Step 2 · 按清单处理（agent 引导 + 你操作）

---

#### ✅ 1. markitdown（必需 · 用来读需求文档）— agent 自动

| 状态 | 含义 | 谁来做 |
|------|------|--------|
| ✅ 已装 | 直接可用 | 无 |
| ❌ 未装 | 解析不了需求文档 | 让 agent 跑 `<skill 目录>/scripts/ensure_markitdown.sh` 自动装；如失败 agent 会原样把报错给你 |

---

#### ⚠️ 2. Node.js / npx（测微信小程序时需要）— agent 尝试，否则人工

| 状态 | 含义 | 谁来做 |
|------|------|--------|
| ✅ ≥ 18 | 满足 weapp-dev-mcp 要求 | 无 |
| ❌ 未装 / < 18 | 跑不动 weapp-dev-mcp | agent 会尝试 `brew install node@18`（macOS）/ `apt install nodejs`（Linux）。失败则让你去 https://nodejs.org 下载 LTS |

---

#### 🛑 3. 微信开发者工具（测小程序时需要）— 只能你做

agent **无法**装（GUI 安装包）。请你：

1. 下载：https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html
2. 安装到默认路径（agent 已写死的探测路径）。
3. 告诉 agent 你的安装路径（如果不是默认路径）。
4. 打开 IDE → 登录 → **设置 → 安全设置 → 服务端口 / CLI / 自动化 → 勾选开启**（默认 `9420`）。
5. 在 shell 设环境变量（agent 可以代设，也可你手动）：
   ```bash
   export WEAPP_WS_ENDPOINT="ws://localhost:9420"
   ```

---

#### 🟢 4. figma MCP server（按设计稿开发时需要）— agent 问你要 token，你填，agent 保存

> **核心变化**：以前要你自己 `export FIGMA_API_KEY`；现在 **agent 用 `AskUserQuestion` 向你索取 token，你填进去后 agent 直接帮你保存**（写进 MCP 配置的 `env` 字段）。你不用碰命令行、不用编辑配置文件。

**agent 必须按这个顺序做：**

**(a) 先问你要 token**（带获取方式备注）

agent 用 `AskUserQuestion` 弹一个问题，问题正文里**必须备注怎么拿 token**，例如：

> **请粘贴你的 Figma Personal Access Token**
> 获取方式：打开 Figma → 右上角头像 → **Settings** → **Security** → **Personal access tokens** → **Generate new token**，权限至少勾选 `File content` 读取 → 复制（token 只显示一次，形如 `figd_xxx...`）。
> 没有设计稿 / 不按 Figma 开发？选「跳过」即可。

（`AskUserQuestion` 的选项天然带「Other」自由输入框，用户把 token 粘进 Other；并额外给一个「跳过 Figma」选项。）

**(b) 你填**——把 token 粘进问题的输入框，或选「跳过 Figma」。

**(c) agent 保存**——拿到 token 后，agent **把 token 字面值直接写进** agent 的 MCP 配置（`<agent 配置目录>/mcp.json`，如 Claude Code `~/.claude/mcp.json`、Cursor `~/.cursor/mcp.json`，Trae 类似），写入前先给你看要写什么并征得同意：

```jsonc
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "figd_用户刚填的真实token" }
    }
  }
}
```

写完后让 agent 重载 MCP，确认工具列表里真的出现 `figma` 工具才算就绪。

> ⚠️ **token 落在 MCP 配置文件里是明文**——agent 必须提醒你：**不要把该配置文件提交进 git / 不要贴到群里**；建议把它加进 `.gitignore`。agent 也**不要把 token 打到日志或回显里**。
> ⚠️ agent **不要替你生成 token**（生成那一步要登录 Figma，只能你做）；agent 只负责「问 + 存」。

> 详细指引见 `<skill 目录>/references/figma.md`。

---

#### 🟠 5. weapp-dev MCP server（测小程序时需要）— init 只装 MCP，端点等以后再校验

> **init 阶段只做一件事：把 MCP server 装进配置。** 不校验 9420 端点是否有效、不要求你此刻开好 IDE——**那些留到后面真正打开小程序、要跑测试时（阶段 6）再校验**。这样 init 不会卡在「IDE 还没开」上。

**(a) agent 把 MCP server 配进 agent 的 MCP 配置**（征得你同意后写入）

```jsonc
{
  "mcpServers": {
    "weapp-dev": {
      "command": "npx",
      "args": ["-y", "@yfme/weapp-dev-mcp"],
      "env": { "WEAPP_WS_ENDPOINT": "ws://localhost:9420" }
    }
  }
}
```

端点默认填 `ws://localhost:9420`（微信开发者工具自动化端口默认值）。**init 时不验证它是否连得通**。

**(c) agent 把小程序 MCP 工具权限写进「当前 agent 的免确认配置」**

weapp-dev-mcp 官方说明：调它的工具时每次弹权限确认会**打断与微信开发者工具的连接**，导致拿不到连贯的 console 日志。所以要**预先把这些工具加进免确认名单**。

⚠️ **写到哪个文件、用什么格式，取决于你用的是哪个 coding agent——下面的 `~/.claude/settings.local.json` + `permissions.allow` 只是 Claude Code 的写法（也是默认示例）。** agent 必须**先判断当前自己是哪个 agent**，再写进对应的免确认/自动批准配置：

| 你用的 agent | 写到哪里 | 字段 / 格式 |
|------|---------|------------|
| **Claude Code** | 全局 `~/.claude/settings.local.json`（项目级安装则 `<项目根>/.claude/settings.local.json`） | `permissions.allow` 数组，每项 `mcp__<server名>__<工具名>` |
| **Cursor** | Cursor 的 MCP / 工具自动批准设置 | 以 Cursor 文档为准（通常是 per-tool「auto-run / always allow」开关，不一定是 JSON 数组） |
| **Trae / 其他** | 该 agent 的「工具免确认 / auto-approve」配置 | **以该 agent 官方文档为准** |

**通用规则**（不分 agent）：把下面这 27 个工具全部加进当前 agent 的免确认名单；文件/数组不存在就创建，已存在则**去重合并、不要覆盖用户已有项**；写入前给你看并征得同意。

Claude Code 的具体片段（其他 agent 取这份工具清单、套自己的格式）：

```jsonc
{
  "permissions": {
    "allow": [
      "mcp__weapp-dev__mp_ensureConnection",
      "mcp__weapp-dev__mp_navigate",
      "mcp__weapp-dev__mp_screenshot",
      "mcp__weapp-dev__mp_callWx",
      "mcp__weapp-dev__mp_getLogs",
      "mcp__weapp-dev__mp_currentPage",
      "mcp__weapp-dev__mp_listProjects",
      "mcp__weapp-dev__mp_setDefaultProject",
      "mcp__weapp-dev__page_getElement",
      "mcp__weapp-dev__page_getElements",
      "mcp__weapp-dev__page_waitElement",
      "mcp__weapp-dev__page_waitTimeout",
      "mcp__weapp-dev__page_getData",
      "mcp__weapp-dev__page_setData",
      "mcp__weapp-dev__page_callMethod",
      "mcp__weapp-dev__element_tap",
      "mcp__weapp-dev__element_input",
      "mcp__weapp-dev__element_callMethod",
      "mcp__weapp-dev__element_getData",
      "mcp__weapp-dev__element_setData",
      "mcp__weapp-dev__element_getInnerElement",
      "mcp__weapp-dev__element_getInnerElements",
      "mcp__weapp-dev__element_getWxml",
      "mcp__weapp-dev__element_getStyles",
      "mcp__weapp-dev__element_scrollTo",
      "mcp__weapp-dev__element_getAttributes",
      "mcp__weapp-dev__element_getBoundingClientRect"
    ]
  }
}
```

> ⚠️ **工具名前缀必须和 MCP 配置里的 server 名一致**。本 skill 把 server 命名为 `weapp-dev`，所以是 `mcp__weapp-dev__*`。**注意**官方 README 用的是 `mcp__weapp-dev-mcp__*`（它把 server 命名为 `weapp-dev-mcp`）——前缀对不上不生效。你在第 (a) 步若把 server 改了名，这里也要跟着改成 `mcp__<你的server名>__*`。
> 💡 不测小程序可跳过这步。
> 💡 若当前 agent 不支持「工具免确认」机制，则跳过此步，改为接受每次调用都会弹确认（代价是日志可能不连贯）。

**(d) 端点校验推迟到阶段 6**

到真正要测小程序时，再确认：微信开发者工具已启动、登录、开了 9420 自动化端口，端点能连上。届时连不通再按 `references/miniprogram-testing.md` 排查，**不在 init 阶段卡这一步**。

---

#### 🛑 6. Chrome MCP（测 Web 前端时需要）— 只能你做

agent **无法**装（浏览器扩展只能从扩展商店装）。

请你：

1. 装 "Claude in Chrome" 浏览器扩展（Chrome 商店）。
2. 打开任意网页。
3. 点扩展图标 → 授权连接到 Claude。
4. agent 这边会自动检测 `mcp__*Chrome*` 工具是否出现。

详细步骤见 `<skill 目录>/references/web-testing.md`。

---

### Step 3 · 给我一份环境健康度小结

agent 跑完后会给你一份类似这样的快照（✅ / ⚠️ / ❌ + 下一步）：

```
📋 环境健康度快照

✅ markitdown:        <版本号 / OK>
⚠️ Node.js:           <v18.x / 缺失（agent 已尝试装 / 你需要手装）>
🟢 figma MCP:         <agent 已写入配置 + token 已保存 / 你选了跳过 / 待你填 token>
🟠 weapp-dev MCP:     <agent 已写入配置（端点默认 ws://localhost:9420，9420 连通性留到阶段 6 再校验）>
🟠 weapp-dev 权限:    <agent 已把 mcp__weapp-dev__* 工具加进【当前 agent 的免确认配置】（Claude Code=settings.local.json，其他 agent 按其文档）/ 不测小程序或 agent 不支持则跳过>
🛑 微信开发者工具:     <路径 / 缺失>（仅测小程序时需要，可后补）
🛑 Chrome MCP:        <工具可见 / 缺失（你装扩展了吗）>

🎯 本次项目要用的：<web 前端 / 微信小程序 / 都用>
⏭️ 下一步：<用 btf 主流程跑需求 / 修某项前置>
```

> 注：token 类已由 agent「问你要 → 你填 → agent 存进 MCP 配置」搞定，快照里不再有「待你 export 环境变量」这类项；9420 端点连通性**不在 init 校验**，留到阶段 6 打开小程序时再验。

---

## 🚦 决策矩阵：你下一步该做什么

| 当前情况 | 你接下来要做的 |
|---------|--------------|
| 全部 ✅ + 跑主流程 | 发需求文档，让 agent 跑完整七阶段 |
| 🟢 figma 待填 token | 在 agent 弹的 `AskUserQuestion` 里粘进 Figma token（没设计稿就选「跳过」）——**填完 agent 自动保存，你不用设环境变量** |
| ⚠️ Node.js 缺失 | macOS 让 agent 用 brew 装；其他系统去 https://nodejs.org 下载 |
| 🛑 微信开发者工具缺失 | 测小程序前下载安装、登录、开 9420 端口即可（**init 不卡这步，阶段 6 再校验**） |
| 🛑 Chrome MCP 缺失 | 装 Claude in Chrome 扩展、授权 |
| ❌ 一片红 | 按 1→6 顺序逐项补齐，再回来 |

---

## 🚫 三条红线（agent 与你都不要破）

1. **agent 不要替你生成 Figma token**——生成那一步要登录 Figma，只能你做；agent 只负责用 `AskUserQuestion`「问你要 + 保存」。
2. **token 必须问、不能猜也不能空着配**——MCP 需要 token 时，agent 一定用 `AskUserQuestion`（带获取方式备注）向你索取，拿到后才写进配置；不要写假值、不要留 `${VAR}` 占位指望你后面去 export。
3. **token 是明文、别提交**——写进 MCP 配置文件的 token 是明文，agent 要提醒你别提交进 git、别外传，并建议加进 `.gitignore`；agent 自己也不回显 token。
4. **agent 不要假装 MCP server「已经装好了」**——配完必须检测工具列表里真的出现 `figma` / `mp_*` 才算就绪（小程序的 9420 连通性除外，那个留到阶段 6）。
5. **不要顺势开始解析需求** —— init 到此为止，正式流程另起。

---

## ⏭️ init 完成

到这里就结束了。把上面那份快照发给 agent，确认环境就绪后，下一条消息正式发起需求。