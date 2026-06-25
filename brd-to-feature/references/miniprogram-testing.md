# 微信小程序测试（小程序 MCP）

用于阶段 6 测试微信小程序项目。推荐用 [`weapp-dev-mcp`](https://github.com/yfmeii/weapp-dev-mcp)（npm 包 `@yfme/weapp-dev-mcp`）：基于官方 `miniprogram-automator` SDK + WebSocket 长连接驱动微信开发者工具。相比 CLI 封装类方案，它连一次后复用同一连接、不反复启 CLI，**在复杂项目里更不容易卡死/超时**，并提供显式的超时与重试参数。工具名形如 `mp_*`（应用级）、`page_*`（页面级）、`element_*`（元素级）。

## 缺失检查 + 自动安装

进入小程序测试前，先确认小程序 MCP 是否已连接（列出可用工具，找名字含 `mp_` / `page_` / `element_` 或 `weapp` 的）。**若没有，先问用户是否要现在自动安装**，得到同意后再装——安装会改 agent 的 MCP 配置，不要不打招呼就动。

这个包用 npx 直接跑，无需全局安装，把它配进 agent 的 MCP 配置即可（推荐用 connect 模式连一个已经开着的开发者工具，最稳）：

```jsonc
{
  "mcpServers": {
    "weapp-dev": {
      "command": "npx",
      "args": ["-y", "@yfme/weapp-dev-mcp"],
      "env": {
        "WEAPP_WS_ENDPOINT": "ws://localhost:9420"
      }
    }
  }
}
```

前置要求：本地已装 Node.js 18+、装好微信开发者工具且支持命令行（`cli`/`cli.bat`）、有可在开发者工具中打开的项目。配完通常要让 agent 重新加载 MCP 配置才能看到新工具。

> **Claude Code 建议免确认调用**：用 Claude Code 时，工具调用的权限弹窗可能打断与开发者工具的连接、导致日志获取不连贯。可在项目 `.claude/settings.local.json` 的 `permissions.allow` 里把 `mcp__weapp-dev__*` 系列工具加进去免确认（具体工具名前缀以你 MCP 配置里的服务器名为准）。

> **跨端框架（Taro / uni-app）特别注意**：开发者工具打开/连接的必须是**编译产物目录**（Taro 一般是 `dist/`，但可能被项目改过），不是 `src/` 源码根目录。务必先按项目 `package.json` 里真实的小程序构建脚本编译出产物（见 SKILL.md 的 6a-编译前置），再让开发者工具打开它。

## 准备：启动开发者工具并开启自动化

1. **开启服务端口**：微信开发者工具 → `设置` → `安全设置` → `服务端口` → 开启 **「HTTP 调试」和「自动化测试」**。不开自动化端口连不上。
2. **用命令行启动并开 WebSocket 服务**（端口默认 9420，要和 `WEAPP_WS_ENDPOINT` 一致）：

   ```bash
   # macOS
   /Applications/wechatwebdevtools.app/Contents/MacOS/cli auto --project /path/to/project --auto-port 9420
   # Windows
   "C:\Program Files (x86)\Tencent\微信web开发者工具\cli.bat" auto --project C:\path\to\project --auto-port 9420
   ```

   跨端框架记得把 `--project` 指向编译产物目录。
3. 连接后，**先调 `mp_ensureConnection`** 验证连接并查看系统/页面信息。
4. 也可在配置里设 `WEAPP_AUTOLAUNCH=true` + `WEAPP_PROJECT_PATH` 让它自动检测端口并启动开发者工具（首次约等 45 秒就绪，之后复用连接）。

## IDE 启动 + MCP 就绪自检（测试前必做，跨端框架/原生小程序共用）

进入测试前必须确认小程序 MCP 已稳定连接，按下列步骤自检；任一步失败 → 🔴 STOP（见 guardrails.md 红名单 #11）。

1. **确认编译产物路径**（已在 SKILL.md §6a-编译前置确定：用户提供的 / 用户授权编译的，**不要重新猜测**）。
2. **探测微信开发者工具 cli 路径**（**找不到就问，不要猜**）：
   - 默认探测位置（`scripts/stf-init.sh` 的 2.5 段已做）：Windows `C:\Program Files (x86)\Tencent\微信web开发者工具\cli.bat`；macOS `/Applications/wechatwebdevtools.app/Contents/MacOS/cli`。
   - **探测不到时** → 询问用户三选一：① 给开发者工具 cli 的绝对路径；② 用户自己手动启动 IDE + 开启自动化端口（设置 → 安全设置 → 服务端口 → 开启「HTTP 调试」和「自动化测试」）后告知"已开好"；③ 降级到纯静态分析（产物顶部标"运行通道 ⚠️ 仅静态分析"）。
   - **禁止猜测**：不擅自改默认路径、不假设 WSL/Linux、不假设软链、不假设 IDE 已由别的方式启动。
3. **启动开发者工具**（cli 路径已知后，路径换成探测到的真实路径）：
   ```bash
   "<cli 绝对路径>" auto --project <§6a 确定的产物目录> --auto-port 9420
   ```
4. **sleep ≥ 45 秒**（首次启动；复用连接 ≥ 5 秒）。**不要 sleep 十几秒就重连**——会过早失败。
5. **三项探测**（须全部通过才能开测）：`9420` 端口处于 Listen；开发者工具主窗口标题含目标项目名；`mcp__weapp-dev__*` 工具 ≥ 1 个可用。
6. **连接探测**：先调 `mp_listProjects`（不是 `mp_ensureConnection`）→ 再 `mp_ensureConnection`。
7. **重试退避表**（连接失败时）：

   | 重试次数 | sleep | 必换参数 |
   |---------|-------|----------|
   | 1 | 5s | `reconnect=true` |
   | 2 | 15s | `projectSelection` |
   | 3 | 30s | `reconnect=true + projectSelection` |
   | 4 | 60s | **🔴 STOP 上报用户** |

8. **STOP 信号**：工具消失 / 4 次重试全败 / IDE 主窗口标题不含项目名 → 报告用户，由用户决定走"等待 MCP 恢复"还是"标注降级后继续"。

## 常用工具

- 应用级：`mp_ensureConnection`（确保连接，开测前先调）、`mp_navigate`（navigateTo/redirectTo/reLaunch/switchTab/navigateBack）、`mp_screenshot`（截图）、`mp_callWx`（调 wx API）、`mp_getLogs`（控制台日志）、`mp_currentPage`（当前页路径/参数/数据）、`mp_listProjects` / `mp_setDefaultProject`。
- 页面级：`page_getElement(s)`（按选择器取元素，支持 `[index=N]`）、`page_waitElement`（等元素出现）、`page_waitTimeout`、`page_getData` / `page_setData`（支持嵌套路径、setData 后可 verify）、`page_callMethod`。
- 元素级：`element_tap`（点击，支持坐标偏移、点击后校验路径变化）、`element_input`、`element_callMethod`、`element_getData` / `element_setData`、`element_getWxml`、`element_getStyles`、`element_getAttributes`、`element_scrollTo`、`element_getBoundingClientRect`、`element_getInnerElement(s)`。

## 执行每条用例

按阶段 5 用例逐步操作：

1. `mp_ensureConnection` 确认连接 → `mp_navigate` 跳转到目标页面（**用绝对路径**如 `/pages/mine/mine`；tabBar 页用 `switchTab`，普通页用 `navigateTo`）。
2. 用 `page_waitElement` / `page_waitTimeout` 等页面就绪，再用 `element_tap` / `element_input` 执行操作。
3. 用 `page_getData` / `element_getData` 或 `mp_currentPage` 读状态，核对功能预期。
4. 用 `mp_getLogs` 看控制台确认无报错。
5. UI 还原类用例：`mp_screenshot` 截图对照 Figma 设计稿核对关键视觉。

## 操作自定义组件

`page_waitElement` 不适用于自定义组件内部元素。处理组件内元素用：

- `element_tap` / `element_input` / `element_getWxml` 等支持传 `innerSelector`：`{ "selector": "#my-component", "innerSelector": ".inner-button" }`。
- 或用 `element_getInnerElement(s)` 配合 `targetSelector` 查询。
- 需要"等"组件内元素时，用 `page_waitTimeout` 配合元素查询轮询，而不是 `page_waitElement`。

## 发现问题 → 自愈

- 渲染缺失 / 数据错误 / 跳转异常 / 接口失败 → 定位代码 → 修复 → 重跑该用例。
- 记录每轮"问题 / 根因 / 修复 / 复测结果"。
- 同一用例尝试上限（建议 3 次）仍不过，停下报告用户。

## 备注

- 小程序自动化对真机能力有限制，部分原生组件（map、video、原生支付等）无法完全自动化断言。遇到这类用例，做到可自动化的部分，其余在回归文档里标注为"需人工验证"。
- 连不上多半是没开「自动化测试」端口，或 `WEAPP_WS_ENDPOINT` 端口和 `--auto-port` 不一致。
- 官方参考：[微信开发者工具 CLI](https://developers.weixin.qq.com/miniprogram/dev/devtools/cli.html)、[小程序自动化 SDK](https://developers.weixin.qq.com/miniprogram/dev/devtools/auto/quick-start.html)。

## MCP 连接失败处理

按严重程度分级处理（与 SKILL.md 红名单 #11 配合）：

1. **首次连接 60s 超时**：先 sleep 30s 再调 `mp_listProjects` 探测 IDE 状态（不是直接 `mp_ensureConnection` 重连）。
2. **连接后立即关闭（Connection closed）**：可能是 IDE 弹窗未消（"未受信任项目"提示、"选择项目"对话框），请用户打开 IDE 屏幕手动确认。
3. **MCP 工具消失**：MCP 服务端进程异常，需要用户重启会话或重新加载 MCP 配置。
4. **连续 4 次重试仍失败**（backoff 5/15/30/60s，见 SKILL.md 阶段 6b-前置）：🔴 **STOP** 上报用户，禁止自行降级到静态分析并继续产出报告。
5. **降级选项**：若用户明确同意降级为静态分析，**必须**在产出物顶部显式标注"运行通道：⚠️ 仅静态分析"，并在遗留事项里列出运行时复测脚本（MCP 恢复后补测）。
