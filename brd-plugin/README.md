# brd-to-feature（plugin）

需求驱动的端到端开发流水线，打包为 Claude 插件。把一份需求文档（pptx/pdf/docx/md/txt）和可选的 Figma 设计稿，变成**已开发完成、且通过自动化测试**的功能，并沿途产出对应文档。

## 它做什么

固定阶段、带两个人工卡点的工作流：

1. **解析输入** — 需求文档用 [markitdown](https://github.com/microsoft/markitdown) 转 md；设计稿用 Figma MCP 读取；通读整个项目。
2. **技术文档** — 产出技术设计文档 →【人工卡点 1】确认需求理解与方案后才开发。
3. **开发** — 按需求 + 设计稿还原 UI，产出改动文档。
4. **严格代码审查** — 从需求一致性 / 正确性边界 / 安全 / 项目约定 / 可维护性 / 性能六维度严查，阻塞问题当场清零 →【人工卡点 2】测试前确认是否改代码、是否做设计稿截图比对。
5. **测试用例** — 基于验收标准与交互状态产出用例。
6. **自动测试 + 自愈** — 自动判定项目类型，Web 用 Chrome MCP、微信小程序用小程序 MCP 跑测试，发现问题自动修复重跑（有上限，到限报告不强标通过）。
7. **回归文档** — 产出回归文档，结束。

任务类型由 Step 0 自动识别，对应不同文档清单：**完整开发 / 纯分析 / 运行验证 / bug 修复**（详见主 skill 的 SKILL.md）。

## 目录结构

```
brd-plugin/
├── .claude-plugin/
│   └── plugin.json          # 插件元信息（mcpServers 指向 ./.mcp.json）
├── .mcp.json                # 声明 figma(Framelink) + weapp-dev(小程序) 两个 MCP server
├── agents/                  # 三个内部子代理（仅主流程 Task 调用）
│   ├── btf-explore-project.md
│   ├── btf-code-review.md
│   └── btf-run-tests.md
├── commands/
│   └── btf-init.md          # 斜杠命令 /btf-init
├── skills/
│   └── brd-to-feature/      # 主 skill + assets/references/scripts
│       ├── SKILL.md
│       ├── assets/          # 各类文档模板
│       ├── references/      # guardrails / figma / web-testing / miniprogram-testing
│       └── scripts/         # btf-init.sh / ensure_markitdown.sh
├── CONNECTORS.md            # 连接器类别说明
└── README.md
```

## 安装

在 Claude Code / Cowork 里安装本插件。安装后：

- 主 skill `brd-to-feature` 会在命中需求驱动开发场景时自动触发；
- 斜杠命令 `/btf-init` 自动注册，无需手动放命令文件；
- `.mcp.json` 里声明的 `figma` / `weapp-dev` 两个 MCP server 自动注册（**无需手改 MCP 配置**），运行时按需设环境变量即可；
- 三个内部子代理（`agents/`）随插件装好，由主流程在阶段 1c/4/6 用 Task 调用，用户不直接触发。

如果本插件随 zy-skills 仓库一起作为 marketplace 发布，可先添加该 marketplace 再从中安装本插件。

> 在不支持插件格式的 agent（如 Cursor / Trae）里使用：把 `skills/` 拷到 `.claude/skills/`、`agents/` 拷到 `.claude/agents/`、`commands/btf-init.md` 拷到 `.claude/commands/`，并把 `.mcp.json` 里的两个 server 合并进该 agent 的 MCP 配置。插件格式仅在 Claude 生态生效。

## 组件

| 组件 | 名称 | 作用 |
|------|------|------|
| Skill | `brd-to-feature` | 七阶段主流程 + Step 0 任务类型识别 + btf-init 工具初始化说明 |
| Agent（内部） | `btf-explore-project` | 阶段 1c：隔离上下文里只读通读项目，写 `docs/project-survey.md` |
| Agent（内部） | `btf-code-review` | 阶段 4：隔离上下文里只读严格审查改动，写 `docs/code-review.md` |
| Agent（内部） | `btf-run-tests` | 阶段 6：隔离上下文里跑用例 + 自愈 + 维护 bug-tracker |
| Command | `/btf-init` | 只初始化本插件依赖的工具，不解析需求、不开发 |
| MCP | `figma` / `weapp-dev` | 由 `.mcp.json` 声明，分别用于读设计稿 / 测微信小程序 |

三个内部子代理只由主 skill 用 Task 显式调用、不会被自动触发；环境不支持子代理时退化为主上下文内联执行。

## 依赖工具与环境变量

MCP server 已由插件 `.mcp.json` 声明、安装即注册；运行时按任务需要补齐以下工具与环境变量（先跑 `/btf-init` 检测与获取指引）：

- **markitdown**（必需）— 解析需求文档。脚本可命令行自动安装。
- **Figma MCP `figma`**（按设计稿开发时）— 插件已声明 [Framelink](https://github.com/GLips/Figma-Context-MCP)，只需设环境变量 **`FIGMA_API_KEY`**。token 获取：Figma → Settings → Security → Personal access tokens。
- **Chrome MCP**（测 Web 前端时）— 走浏览器扩展，需人工连接（不走 `.mcp.json`）。
- **小程序 MCP `weapp-dev`**（测微信小程序时）— 插件已声明 [weapp-dev-mcp](https://github.com/yfmeii/weapp-dev-mcp)，需设环境变量 **`WEAPP_WS_ENDPOINT`**（如 `ws://localhost:9420`），并启动微信开发者工具开启 9420 自动化端口；需 Node.js 18+。

连接器按能力类别组织（`~~design` / `~~web testing` / `~~miniprogram testing`），详见 `CONNECTORS.md`。各工具的检测/设置/token 获取详见主 skill 的 `references/`（figma.md / web-testing.md / miniprogram-testing.md）。

## 产出物

统一放在目标项目的 `docs/` 下，按任务类型只产出对应文档：

| 任务类型 | 文档 |
|---------|------|
| 完整开发 | technical-design + change-log + code-review + test-cases + test-regression |
| 纯分析 | 单份主报告（如 performance-report.md） |
| 运行验证 | test-cases + run-verification-report |
| bug 修复 | test-cases + bug-tracker + test-regression |

## 红线与兜底

每阶段动手前先过 `references/guardrails.md` 的红灯黑名单（14 条）；遇到失败按其失败兜底表处理。卡点未确认不开发、不放行不测试；工具/token 不假装代办；解析失败或 MCP 不可用绝不静默降级硬产出。

---

源仓库：<https://github.com/zhYAO/skills>
