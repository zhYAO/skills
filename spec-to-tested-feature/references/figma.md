# 用 Figma MCP 读取设计稿

设计稿是开发阶段还原 UI 的依据。在阶段 1b 读取，在阶段 2 沉淀进技术文档，在阶段 3/6 对照还原与核对。

## 前置：确认 MCP 已连接

列出当前可用工具，查找名字含 `figma` 的 MCP 工具。不同 Figma MCP 实现命名不同，但通常提供以下能力之一/若干：

- 获取文件/页面的节点树（file key + node id）。
- 读取某个 frame / 组件的布局、尺寸、间距、约束。
- 读取样式信息：填充色、描边、字体、字号、行高、圆角、阴影。
- 读取设计变量 / token（颜色、间距、字号变量）。
- 导出节点为图片（png/svg），用于像素级比对。

若没有任何 figma 工具，**不要假装能看到设计稿**。**先问用户是否要现在自动安装/连接 Figma MCP**，得到同意后再动手；用户也可以选择跳过设计稿、仅按需求文档开发。

## 缺失时：自动安装 / 连接

征得用户同意后，按所用方案处理（二选一）：

**方案 A：Figma 官方 Dev Mode MCP（推荐，免装包）**
内置在 Figma 桌面应用里，无需安装额外包，但要 Figma 付费席位且开启。让用户：更新 Figma 桌面应用 → 菜单 `Figma` → `Preferences` → 勾选 `Enable Dev Mode MCP Server`，它会在本地 `http://127.0.0.1:3845/sse` 暴露 SSE 端点。然后在 agent 的 MCP 配置里加：

```jsonc
{
  "mcpServers": {
    "figma-dev-mode": { "url": "http://127.0.0.1:3845/sse" }
  }
}
```

**方案 B：社区 Framelink MCP（npx 安装，需 Figma API token）**
适合没有 Dev Mode 的场景。先让用户到 Figma `Settings` → `Security` → 生成 personal access token，然后配置：

```jsonc
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "<用户的 Figma access token>" }
    }
  }
}
```

不要把 token 写进会被提交的文件或打印到日志。配完一般要让 agent 重新加载 MCP 配置才能看到工具。两种方案的具体形态可能随版本变化，以官方文档为准。

## 从用户输入里拿到定位信息

Figma 链接形如：
`https://www.figma.com/design/<FILE_KEY>/<name>?node-id=<NODE_ID>`

从中解析出 `FILE_KEY` 和 `node-id`（注意 URL 里的 `-` 在 API 里通常是 `:`，如 `123-45` → `123:45`）。如果用户只给了链接，先确认要还原的是整份文件还是某个具体 frame。

## 提取清单（沉淀到技术文档）

对每个要实现的页面/组件，提取并记录：

1. **页面/组件清单**：名称、层级、与现有项目组件的对应关系（能复用就复用）。
2. **布局**：栅格/列数、容器宽度、元素排布（flex/grid）、对齐方式。
3. **间距**：外边距、内边距、元素间距——尽量映射到项目已有的 spacing token。
4. **配色**：背景、文字、主题色、边框色——映射到项目 color token。
5. **字体**：字族、字号、字重、行高。
6. **圆角 / 阴影 / 边框**等视觉细节。
7. **交互状态**：default / hover / active / focus / disabled / 选中，以及空态、加载态、错误态——这些常被漏掉，要专门核对。
8. **资源**：图标、插图，确认是用项目已有资源、还是需要从 Figma 导出。

## 还原与核对

- 阶段 3 开发时按上面清单实现，优先复用项目组件与 token，不要硬编码与设计稿不符的值。
- 阶段 6 的"UI 还原类用例"对照设计稿核对关键视觉。必要时用 Figma MCP 导出节点图片，与运行结果做并排比对。
- 还原结论写进回归文档（阶段 7）。
