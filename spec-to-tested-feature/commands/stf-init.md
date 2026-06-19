---
description: 初始化 spec-to-tested-feature skill 所需的工具（markitdown / Figma MCP / Chrome MCP / 小程序 MCP），不解析任何需求。
---

请进入 **spec-to-tested-feature** skill 的 init 流程：**只初始化本 skill 依赖的工具，不要解析任何需求、不要开始开发。**

步骤：

1. 运行 `bash scripts/stf-init.sh`（在 skill 目录下）做一轮检测，读它打印的每项状态。
2. 按 SKILL.md「stf-init 命令：初始化所需工具」一节逐项处理：
   - markitdown：跑 `scripts/ensure_markitdown.sh` 自动装。
   - 小程序 MCP / uv：征得我同意后自动装，并提示配环境变量、开启服务端口。
   - Figma MCP：引导我选方案，若用 Framelink 要告诉我 Figma access token 怎么拿、填哪。
   - Chrome MCP：引导我手动连接浏览器扩展。
3. 最后给我一份小结：哪些已就绪、哪些待我操作（附下一步）、哪些本项目用不到。

**原则**：能命令行自动装的，先问我再装；只能人工的（token、浏览器扩展）给清晰步骤和获取链接。init 到此结束，不要顺势开始做需求。
