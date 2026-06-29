---
description: 初始化 brd-to-feature 所需的工具（markitdown / Figma MCP / Chrome MCP / 小程序 MCP / Node.js），不解析任何需求。**用户主动调用**：用 /btf-init 斜杠命令触发，或显式说"btf-init"。不自动触发。
---

# 🔧 btf-init · 工具初始化

> **目标**：把本 skill 跑起来要的工具一次性检测到位，能 agent 自动装的就 agent 装、装不了的给你清晰的人工步骤。
> **边界**：只准备环境，**不解析需求、不开始开发**。正式流程由你下一条消息发起。

## 🎯 总原则

| 谁来装 | 工具 |
|--------|------|
| ✅ **agent 自动装**（征得你同意后） | markitdown |
| ⚠️ **agent 尝试装，失败再交你** | Node.js（macOS/Linux 包管理器） |
| 🟠 **agent 生成配置片段，你粘贴到 MCP 配置** | figma MCP server、weapp-dev MCP server |
| 🛑 **只能你来**（GUI / 登录 / 浏览器商店） | 微信开发者工具、Figma token、Chrome 扩展 |

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

#### 🟠 4. figma MCP server（按设计稿开发时需要）— agent 配，你拿 token

**这两步分开做：**

**(a) agent 把 MCP server 配进 agent 的 MCP 配置**（这是 agent 能做的）

agent 会尝试自动写入 `<agent 配置目录>/mcp.json`（如 Claude Code 是 `~/.claude/mcp.json`，Cursor 是 `~/.cursor/mcp.json`，Trae 类似），写入前会先给你看要写的内容并征得同意。

写入的片段大致是：
```jsonc
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "${FIGMA_API_KEY}" }
    }
  }
}
```

**(b) 你拿 Figma token + 设环境变量**（这是你必须做的）

1. 打开 Figma → 右上角头像 → **Settings** → **Security** → **Personal access tokens** → 生成新 token。
2. 权限至少给 `File content` 读取。
3. 复制 token（**只显示一次，存好**），设到环境变量：
   ```bash
   export FIGMA_API_KEY="figd_xxx..."
   ```
4. 重启 agent / 重载 MCP，工具列表里会出现 `figma` 工具。

> ⚠️ **不要**把 token 写进会被提交的文件、不要打到日志里、不要贴到群里。

> 详细指引见 `<skill 目录>/references/figma.md`。

---

#### 🟠 5. weapp-dev MCP server（测小程序时需要）— agent 配，你开 IDE + 设环境变量

**(a) agent 把 MCP server 配进 agent 的 MCP 配置**

写入的片段大致是：
```jsonc
{
  "mcpServers": {
    "weapp-dev": {
      "command": "npx",
      "args": ["-y", "@yfme/weapp-dev-mcp"],
      "env": { "WEAPP_WS_ENDPOINT": "${WEAPP_WS_ENDPOINT}" }
    }
  }
}
```

**(b) 你**（已在第 3 步做完）

- IDE 已启动、9420 端口已监听
- 环境变量 `WEAPP_WS_ENDPOINT` 已设

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
🛑 微信开发者工具:     <路径 / 缺失>，9420 端口: <监听中 / 未监听>
🟠 figma MCP 配置:    <agent 已写入 / 待粘贴>
✅ FIGMA_API_KEY:     <已设 / 未设>
🟠 weapp-dev MCP 配置: <agent 已写入 / 待粘贴>
✅ WEAPP_WS_ENDPOINT: <已设 / 未设>
🛑 Chrome MCP:        <工具可见 / 缺失（你装扩展了吗）>

🎯 本次项目要用的：<web 前端 / 微信小程序 / 都用>
⏭️ 下一步：<用 btf 主流程跑需求 / 修某项前置>
```

---

## 🚦 决策矩阵：你下一步该做什么

| 当前情况 | 你接下来要做的 |
|---------|--------------|
| 全部 ✅ + 跑主流程 | 发需求文档，让 agent 跑完整七阶段 |
| ⚠️ / ❌ 全是 token 类（FIGMA_API_KEY / WEAPP_WS_ENDPOINT） | 拿 token、设环境变量、**重启 agent** 让 MCP 重连 |
| ⚠️ Node.js 缺失 | macOS 让 agent 用 brew 装；其他系统去 https://nodejs.org 下载 |
| 🛑 微信开发者工具缺失 | 下载安装、登录、开 9420 端口、设 `WEAPP_WS_ENDPOINT` |
| 🛑 Chrome MCP 缺失 | 装 Claude in Chrome 扩展、授权 |
| 🟠 MCP 配置待粘贴 | 看 agent 给的 JSON 片段，粘进 agent 的 MCP 配置（路径因 agent 而异，agent 会告诉你） |
| ❌ 一片红 | 按 1→6 顺序逐项补齐，再回来 |

---

## 🚫 三条红线（agent 与你都不要破）

1. **agent 不要替你拿 Figma / 微信开发者工具的 token**——这些只能人工（要登录 Figma / 要点 IDE 设置）。
2. **agent 不要假装 MCP server "已经装好了"**——配完必须检测工具列表里真的出现 `figma` / `mp_*` 才算就绪。
3. **不要顺势开始解析需求** —— init 到此为止，正式流程另起。

---

## ⏭️ init 完成

到这里就结束了。把上面那份快照发给 agent，确认环境就绪后，下一条消息正式发起需求。