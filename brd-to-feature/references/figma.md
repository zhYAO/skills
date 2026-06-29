# 用 Figma MCP 读取设计稿

设计稿是开发阶段还原 UI 的依据。在阶段 1b 读取，在阶段 2 沉淀进技术文档，在阶段 3/6 对照还原与核对。

## 前置：确认 MCP 已连接

列出当前可用工具，查找名字含 `figma` 的 MCP 工具。不同 Figma MCP 实现命名不同，但通常提供以下能力之一/若干：

- 获取文件/页面的节点树（file key + node id）。
- 读取某个 frame / 组件的布局、尺寸、间距、约束。
- 读取样式信息：填充色、描边、字体、字号、行高、圆角、阴影。
- 读取设计变量 / token（颜色、间距、字号变量）。
- 导出节点为图片（png/svg），用于像素级比对。

若没有任何 figma 工具，**不要假装能看到设计稿**。**默认直接装 Framelink MCP（见下），不必让用户在多个方案间选择**；用户若明确表示没有设计稿，可跳过设计稿、仅按需求文档开发。

## 缺失时：安装 Framelink MCP（默认方案）

默认使用社区 Framelink MCP（npx 安装，走 Figma API token）。安装会改 agent 的 MCP 配置，动手前可简单告知用户，但无需让其在方案间二选一。

需要 Figma access token。**token 用「问 + 存」流程拿（见 `commands/btf-init.md` 第 4 项）**：agent 用 `AskUserQuestion` 向用户索取 token，问题正文里**必须备注获取方式**——Figma → 右上角头像 → `Settings` → `Security` → `Personal access tokens` → `Generate new token`，权限至少给 `File content` 读取，复制（只显示一次，形如 `figd_xxx...`）。用户把 token 粘进问题输入框后，**agent 把 token 字面值直接写进** MCP 配置的 `env`（写入前给用户看并征得同意）：

```jsonc
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": { "FIGMA_API_KEY": "figd_用户填的真实token" }
    }
  }
}
```

不要让用户自己 `export` 环境变量——agent 负责保存。**token 在配置文件里是明文**：提醒用户别提交进 git、建议加 `.gitignore`，agent 也不要把 token 打到日志或回显。配完一般要让 agent 重新加载 MCP 配置才能看到工具。具体形态可能随版本变化，以 [Framelink 官方文档](https://github.com/GLips/Figma-Context-MCP) 为准。

> 备选：如果用户有 Figma 付费席位、偏好官方 Dev Mode MCP（免 token，内置在 Figma 桌面应用，开启后走本地 `http://127.0.0.1:3845/sse`），也可用；但**默认不主动走这条**，仅在用户明确要求时采用。

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
