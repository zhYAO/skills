---
description: 初始化 brd-to-feature 插件所需的工具（markitdown / Figma MCP / Chrome MCP / 小程序 MCP），不解析任何需求。
---

请进入 **brd-to-feature** 插件的 init 流程：**只初始化本插件依赖的工具，不要解析任何需求、不要开始开发。**

> Figma（`figma`/Framelink）与小程序（`weapp-dev`）两个 MCP server 已由插件 `.mcp.json` 声明、安装即注册——**不要手改我的 MCP 配置**。init 只检测就绪状态并指导我补齐环境变量与外部前置。

步骤：

1. 运行 `bash ${CLAUDE_PLUGIN_ROOT}/skills/brd-to-feature/scripts/btf-init.sh` 做一轮检测，读它打印的每项状态。
2. 按 SKILL.md「btf-init 命令：初始化所需工具」一节逐项处理：
   - markitdown：跑 `${CLAUDE_PLUGIN_ROOT}/skills/brd-to-feature/scripts/ensure_markitdown.sh` 自动装。
   - 小程序 MCP（`weapp-dev`，已声明）：若 `mp_*` 工具缺失，指导我设环境变量 `WEAPP_WS_ENDPOINT`（如 `ws://localhost:9420`）、启动微信开发者工具并开启自动化端口（需 Node.js 18+），不要改 MCP 配置。
   - Figma MCP（`figma`/Framelink，已声明）：若 `figma` 工具缺失，告诉我 Figma access token 怎么拿，并指导我设到环境变量 `FIGMA_API_KEY`、重载 MCP。
   - Chrome MCP：引导我手动连接浏览器扩展（不走 `.mcp.json`）。
3. 最后给我一份小结 + **环境健康度快照**，包含：
   - markitdown 版本与检测状态
   - Node.js 版本（要求 ≥18）
   - 微信开发者工具安装路径（如可定位）+ 主窗口标题
   - 9420 端口监听状态
   - 当前可用的 MCP 工具列表（按前缀分类：`mcp__weapp-dev__*`、`mcp__Claude_in_Chrome__*`、`figma`、`mp_*` 等）
   - 环境变量是否已设：`FIGMA_API_KEY`、`WEAPP_WS_ENDPOINT`
   - 小结：哪些已就绪、哪些待我操作（附下一步）、哪些本项目用不到

**原则**：
- 能命令行自动装的（如 markitdown），直接装、装完告诉我结果；**如果安装报错，立刻停下把报错原样给我**，由我决定下一步。
- 工具路径未知时（如微信开发者工具的 `cli.bat` 不在默认位置、自定义 IDE 安装路径），**主动询问用户**怎么打开 / 在哪，**不要擅自猜测**默认路径、不要假设符号链接、不要假设已通过其他方式启动。
- 只能人工的（环境变量、token、浏览器扩展）给清晰步骤和获取链接。
- init 到此结束，不要顺势开始做需求。
