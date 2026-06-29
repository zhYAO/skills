---
description: 主动调用 brd-to-feature 主流程，按用户当前输入做 Step 0 任务路由（完整开发 / 纯分析 / 运行验证 / bug 修复）。
---

# /btf · brd-to-feature 主流程入口

用户在 Claude Code 里输入 `/btf` 触发本命令。

**执行**：

1. 把用户的请求作为本轮输入，启动 brd-to-feature 主流程。
2. 主流程跑 §Step 0 任务类型路由（完整开发 / 纯分析 / 运行验证 / bug 修复），按对应精简路径执行。
3. 若用户带具体输入（如"用 btf 做 /path/to/requirement.docx"），把该输入作为本轮的请求传给主流程。
4. 若用户没带输入，主动问"这次跑哪个需求？先说任务类型与输入材料。"

**工具未初始化？**：先让用户跑 `/btf-init`（详见 `commands/btf-init.md`）——**先 init 再 /btf**。
