# Connectors

本插件按**能力类别**引用外部工具，而不是写死某个产品。下表列出每类用到的连接器、本插件默认/内置的实现，以及可替换的其它选项。

## 这些连接器怎么用

| 类别 | 占位符 | 默认 / 内置实现 | 其它可选 | 接入方式 |
|------|--------|----------------|----------|----------|
| 设计稿读取 | `~~design` | **Figma（Framelink MCP）** | Figma 官方 Dev Mode MCP | 插件 `.mcp.json` 已声明 `figma`；设环境变量 `FIGMA_API_KEY` 即可 |
| Web 前端测试 | `~~web testing` | **Chrome（Claude in Chrome 扩展）** | 其它浏览器自动化 MCP | 浏览器扩展，人工连接（不走 `.mcp.json`） |
| 微信小程序测试 | `~~miniprogram testing` | **weapp-dev MCP（`@yfme/weapp-dev-mcp`）** | 其它小程序自动化 MCP | 插件 `.mcp.json` 已声明 `weapp-dev`；设 `WEAPP_WS_ENDPOINT` + 启微信开发者工具 |

## 内置 MCP（插件 .mcp.json 已声明）

安装插件即注册以下 server，**无需手改 MCP 配置**，运行时按需设对应环境变量：

- `figma`（Framelink）— `npx -y figma-developer-mcp --stdio`，环境变量 `FIGMA_API_KEY`。
- `weapp-dev`（小程序）— `npx -y @yfme/weapp-dev-mcp`，环境变量 `WEAPP_WS_ENDPOINT`（如 `ws://localhost:9420`），并需启动微信开发者工具开启自动化端口。

## 不走 .mcp.json 的连接器

- **Chrome MCP**：通过浏览器扩展 + 授权连接，无法用 `.mcp.json` 声明，需用户手动连（见 `skills/brd-to-feature/references/web-testing.md`）。

## 按需接入

只测小程序就不必设 `FIGMA_API_KEY`；只做无设计稿的需求就不必连 Figma；只测 Web 就不必启微信开发者工具。`/btf-init` 会检测各连接器就绪状态并指出还差哪一步。
