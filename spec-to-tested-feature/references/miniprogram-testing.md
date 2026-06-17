# 微信小程序测试（小程序 MCP）

用于阶段 6 测试微信小程序项目。推荐用 [`wechat-devtools-mcp`](https://github.com/WaterTian/wechat-devtools-mcp)：把微信开发者工具 CLI 封装成 MCP，提供 8 个聚合工具覆盖小程序开发/测试/调试全流程。工具名形如 `wechat_ide` / `wechat_automator` / `wechat_inspector` / `wechat_screenshot` / `wechat_navigate` / `wechat_file` 等（按当前环境实际可用的为准）。

## 缺失检查 + 自动安装

进入小程序测试前，先确认小程序 MCP 是否已连接（列出可用工具，找名字含 `wechat` / `miniprogram` 的）。**若没有，先问用户是否要现在自动安装**，得到同意后再装——安装会改全局工具环境和 agent 的 MCP 配置，不要不打招呼就动。

征得同意后：

```bash
# 1. 安装 uv（已有可跳过）
pip install uv

# 2. 一键装到全局隔离环境
uv tool install wechat-devtools-mcp --force

# 验证
uv tool list   # 应能看到 wechat-devtools-mcp
```

然后把 MCP 配进 agent（不同编辑器配置文件不同，下面是通用形态，路径按用户实际安装位置填，Windows 下反斜杠要转义）：

```jsonc
{
  "mcpServers": {
    "wechat-devtools": {
      "command": "uvx",
      "args": ["wechat-devtools-mcp"],
      "env": {
        "WECHAT_DEVTOOLS_CLI": "<微信开发者工具 CLI 路径，如 .../cli.bat 或 macOS 下的 cli>",
        "WECHAT_PROJECT_PATH": "<小程序项目绝对路径>"
      }
    }
  }
}
```

两个环境变量都必填：`WECHAT_DEVTOOLS_CLI`（开发者工具 CLI 绝对路径）、`WECHAT_PROJECT_PATH`（小程序项目绝对路径）。配完通常要让 agent 重新加载 MCP 配置才能看到新工具。

> **跨端框架（Taro / uni-app）特别注意**：`WECHAT_PROJECT_PATH` 必须指向**编译产物目录**（Taro 一般是 `dist/`，但可能被项目改过），不是 `src/` 源码根目录。务必先按项目 `package.json` 里真实的小程序构建脚本编译出产物（见 SKILL.md 的 6a-编译前置），再把路径指过去。

升级：`uv tool upgrade wechat-devtools-mcp`。

## 准备（无论自动还是手动安装，都要做这步）

1. **必须开启微信开发者工具的服务端口**：`设置` → `安全设置` → `服务端口` → 开启。不开端口 AI 下不了指令，最常见的报错就是 `CLI_TIMEOUT`。
2. 用 `wechat_ide(action='open')` 启动/连接 IDE；需要采集运行时日志时用 `wechat_ide(action='open', cdp_enabled=True)`，它会以调试模式启动。
3. 若 MCP 未连接，回到上面的「缺失检查 + 自动安装」。

## 常用能力

- `wechat_ide`：open / login / status / close 等 IDE 生命周期管理。
- `wechat_automator`：start / tap / input / set_data / call_method / page_stack / page_data / storage 等自动化交互。
- `wechat_inspector`：采集 console / CDP 运行时日志。
- `wechat_screenshot`：界面截图（支持长图拼接），用于 UI 还原比对。
- `wechat_navigate`：跳转页面并采集 CDP 日志。
- `wechat_file`：读取项目信息、页面列表、页面/文件内容。

## 执行每条用例

按阶段 5 用例逐步操作：

1. 用 `wechat_navigate` 跳转到目标页面。
2. 用 `wechat_automator` 执行操作（tap / input / 滚动）。
3. 用 `wechat_automator` 读元素属性或页面 data，核对功能预期。
4. 用 `wechat_inspector` 看 console/CDP 日志确认无报错。
5. UI 还原类用例：`wechat_screenshot` 截图对照 Figma 设计稿核对关键视觉。

## 发现问题 → 自愈

- 渲染缺失 / 数据错误 / 跳转异常 / 接口失败 → 定位代码 → 修复 → 重跑该用例。
- 记录每轮"问题 / 根因 / 修复 / 复测结果"。
- 同一用例尝试上限（建议 3 次）仍不过，停下报告用户。

## 备注

- 小程序自动化对真机能力有限制，部分原生组件（map、video、原生支付等）无法完全自动化断言。遇到这类用例，做到可自动化的部分，其余在回归文档里标注为"需人工验证"。
- `wechat_inspector` 报"CDP 采集失败"：多半是手动开了开发者工具没监听调试端口。关掉它，改用 `wechat_ide(action='open', cdp_enabled=True)` 让它自动以调试模式启动。
- 官方参考：[微信开发者工具 CLI](https://developers.weixin.qq.com/miniprogram/dev/devtools/cli.html)、[小程序自动化 SDK](https://developers.weixin.qq.com/miniprogram/dev/devtools/auto/quick-start.html)。
