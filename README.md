# work-skills

工作中用到的 Claude / coding agent skills 集合。每个子目录是一个**独立可取用的单元**：一个 skill 把「触发条件 + 工作流程 + 模板 + 脚本」打包成一份 `SKILL.md`，拷到目标 agent 的 skills 目录下即可用。

> 安装与跨 agent 适配：见各 skill 自己的 `INSTALL.md`（如有）。每个 skill 的 SKILL.md 顶部 frontmatter 写明触发条件——多数 skill 凭 description 自然语言匹配自动加载；**brd-to-feature 是用户主动调用型**（`disable-model-invocation: true`），用 `/btf` 斜杠命令或显式说"用 btf"才触发，避免误加载。

---

## skill 的工作原理

- **触发**：SKILL.md frontmatter 的 `description` 字段是自然语言触发器——只要用户的请求和它描述的场景匹配，agent 就会自动加载整个 skill。**brd-to-feature 是例外**：用 `disable-model-invocation: true` 强制用户主动调用（`/btf` 命令或显式说"用 btf"），不靠自然语言自动匹配。
- **内容**：SKILL.md 描述「按什么步骤完成任务」，可附带：
  - `scripts/` — 可执行脚本（agent 调用）
  - `references/` — 按需加载的参考文档（如 guardrails、连接器使用手册）
  - `assets/` — 模板等产出物素材
  - `commands/` — Claude Code 斜杠命令（拷到 `.claude/commands/` 即用 `/name` 触发；其它 agent 直接说命令名也行）
  - `skills/` — 内部 fork 子 skill（在隔离上下文里跑重活，避免污染主上下文）
- **跨 agent 兼容**：skill 是 LLM 语义层的概念，不绑死任何特定 agent 的私有格式。理论上任何支持「Skill 工具 + context:fork」的 agent 都能用（Claude Code / Trae / Cursor / Codex 等）。

---

## 单元列表

| 名称 | 形态 | 作用 | 适用场景 |
|------|------|------|----------|
| [brd-to-feature](./brd-to-feature) | skill（跨 agent · **用户主动调用**） | 需求驱动的端到端开发工作流：解析需求文档 + Figma 设计稿 → 技术文档（卡点1）→ 开发 → 严格代码 review（卡点2）→ 测试用例 → 自动化测试自愈（带 bug 状态跟踪） → 回归文档。任务类型由 Step 0 自动识别（完整开发 / 纯分析 / 运行验证 / bug 修复）。测试用 Chrome MCP（Web 前端）或小程序 MCP（微信小程序）。 | 拿到需求文档/设计稿需要"从需求到测试一条龙"完成 Web 前端或微信小程序功能开发；或拿到项目路径做性能/代码/安全审计（走纯分析路径）；或修 bug / 处理报错（走 bug 修复路径，含 bug 状态机跟踪）。跨端框架（Taro / uni-app）按用户选定的目标端编译后再测。**主动调用**：Claude Code 用 `/btf` 斜杠命令，其他 agent 显式说"用 btf"或"brd-to-feature"。详见 [brd-to-feature/INSTALL.md](./brd-to-feature/INSTALL.md) 安装指引。 |

---

### brd-to-feature

七阶段、两个人工卡点的开发流水线，跑在支持 MCP 的 coding agent 上：

1. **解析输入** — 用 [markitdown](https://github.com/microsoft/markitdown) 把需求文档（pptx/pdf/docx/md/txt）转成 md（自动检测/安装/验证）；用 Figma MCP 读取设计稿；通读整个项目。
2. **技术文档** —【人工卡点1】产出技术设计文档，停下确认需求理解与方案，确认后才开发。
3. **开发** — 按需求 + 设计稿还原 UI，产出代码改动文档。
4. **严格代码 review** — 从需求一致性 / 正确性边界 / 安全 / 项目约定 / 可维护性 / 性能六个维度严查，阻塞级问题当场修复清零，产出审查报告。【人工卡点2】测试前停下，问是否还要改代码、是否做开发页面与 Figma 设计稿的截图比对，放行后才测试。
5. **测试用例** — 基于验收标准与交互状态产出用例文档。
6. **自动测试 + 自愈** — 自动判定项目类型，Web 前端用 Chrome MCP、微信小程序用小程序 MCP 跑测试，发现问题自动修复重跑（有上限，到限报告不强行标过）。
7. **回归文档** — 产出测试回归文档，结束。

**btf-init 命令（初始化工具）**：正式开干前可先说 `btf-init`（或 Claude Code 里用 `/btf-init` 斜杠命令，加前缀以避开内置的 `/init`）。它只准备本 skill 依赖的工具、不解析需求——**能 agent 自动装的绝不让你手装**（如 markitdown、MCP server 配置片段），**装不了的明确告诉你怎么做**（如 Figma token、Chrome 扩展）。

**跨 agent 安装**：见 [brd-to-feature/INSTALL.md](./brd-to-feature/INSTALL.md)，按 Claude Code / Trae / Cursor 分别给出步骤。

**跨端框架支持**：自动识别 Taro（`@tarojs/*`）/ uni-app（`@dcloudio/*`），会先问测哪个目标端（小程序 / H5），并按项目 `package.json` 里真实的构建脚本先编译再测——小程序测试指向编译产物目录而非源码根。

依赖：markitdown（脚本自动安装）、Figma MCP（读设计稿，可选）、Chrome MCP 或小程序 MCP（自动化测试，小程序推荐 [weapp-dev-mcp](https://github.com/yfmeii/weapp-dev-mcp)，基于 miniprogram-automator + WebSocket 长连接，复杂项目更抗卡）。各工具的检测/安装/token 获取详见 skill 内 `SKILL.md` 与 `references/`。

产出物统一放在目标项目的 `docs/` 下：`technical-design.md`、`change-log.md`、`code-review.md`、`test-cases.md`、`test-regression.md`、`bug-tracker.md`、`{scope}-report.md`、`run-verification-report.md`（按任务类型只产对应文档）。

---

## 文档模板与任务类型对应

> 由 Step 0 任务类型识别决定（详见 [brd-to-feature/SKILL.md](./brd-to-feature/SKILL.md)）。

| 任务类型 | 必出文档模板 |
|---------|--------------|
| 完整开发任务 | technical-design + change-log + code-review + test-cases + test-regression |
| 纯分析任务 | analysis-report（单份主报告） |
| 运行验证任务 | test-cases + run-verification-report |
| bug 修复任务 | test-cases（复现 + 验收用例） + bug-tracker（状态跟踪表） + test-regression（§6 bug 修复回归章节） |

模板文件均在 `brd-to-feature/assets/` 目录下，顶部均带「运行通道」必填字段，缺则视为模板不合规。

---

## 目录约定

每个 skill 是独立的目录：

```
work-skills/
├── README.md
└── <skill-name>/
    ├── SKILL.md          # 必需：触发条件 + 工作流程
    ├── INSTALL.md        # 推荐：跨 agent 安装指引
    ├── scripts/          # 可选：可执行脚本
    ├── references/       # 可选：按需加载的参考文档
    ├── assets/           # 可选：模板等产出物素材
    ├── commands/         # 可选：Claude Code 斜杠命令
    └── skills/           # 可选：内部 fork 子 skill（在隔离上下文跑重活）
```

新增 skill 时，建一个同名目录、写好 `SKILL.md` + `INSTALL.md`，并在上方「单元列表」表格里补一行。