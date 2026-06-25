# work-skills

工作中用到的 Claude / coding agent skills 集合。每个子目录是一个独立 skill，可单独取用。

## 什么是 skill

skill 是一份给 coding agent（Claude Code / Cursor / Trae 等）的"工作剧本"：核心是一个 `SKILL.md`，描述何时触发、按什么步骤完成任务，可附带脚本、参考文档和模板。把 skill 目录放进项目的 `.claude/skills/` 下，agent 会在匹配到对应场景时自动加载并按其流程工作。

## 如何使用

把需要的 skill 目录拷贝（或软链）到目标项目的 `.claude/skills/` 下即可，例如：

```bash
cp -R spec-to-tested-feature /path/to/your-project/.claude/skills/
```

之后在该项目里向 agent 描述任务，命中 skill 的触发条件时会自动启用。

## skill 列表

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [spec-to-tested-feature](./spec-to-tested-feature) | 需求驱动的端到端开发工作流：解析需求文档 + Figma 设计稿 → 技术文档（卡点1）→ 开发 → 严格代码 review（卡点2）→ 测试用例 → 自动化测试自愈（带 bug 状态跟踪） → 回归文档 | 拿到需求文档/设计稿需要"从需求到测试一条龙"完成 Web 前端或微信小程序功能开发；或拿到项目路径做性能/代码/安全审计（走纯分析路径）；或修 bug / 处理报错（走 bug 修复路径，含 bug 状态机跟踪）。任务类型由 Step 0 自动识别（详见 SKILL.md）。 |

### spec-to-tested-feature

七阶段、两个人工卡点的开发流水线，跑在支持 MCP 的 coding agent 上：

1. **解析输入** — 用 [markitdown](https://github.com/microsoft/markitdown) 把需求文档（pptx/pdf/docx/md/txt）转成 md（自动检测/安装/验证）；用 Figma MCP 读取设计稿；通读整个项目。
2. **技术文档** —【人工卡点1】产出技术设计文档，停下确认需求理解与方案，确认后才开发。
3. **开发** — 按需求 + 设计稿还原 UI，产出代码改动文档。
4. **严格代码 review** — 从需求一致性 / 正确性边界 / 安全 / 项目约定 / 可维护性 / 性能六个维度严查，阻塞级问题当场修复清零，产出审查报告。【人工卡点2】测试前停下，问是否还要改代码、是否做开发页面与 Figma 设计稿的截图比对，放行后才测试。
5. **测试用例** — 基于验收标准与交互状态产出用例文档。
6. **自动测试 + 自愈** — 自动判定项目类型，Web 前端用 Chrome MCP、微信小程序用小程序 MCP 跑测试，发现问题自动修复重跑（有上限，到限报告不强行标过）。
7. **回归文档** — 产出测试回归文档，结束。

**stf-init 命令（初始化工具）**：正式开干前可先说 `stf-init`（或 Claude Code 里用 `/stf-init` 斜杠命令，加前缀以避开内置的 `/init`），它只准备本 skill 依赖的工具、不解析需求——检测并自动安装能命令行装的（markitdown / 小程序 MCP），对只能人工的（Chrome 扩展、Figma access token）给出步骤和 token 获取方式。

**跨端框架支持**：自动识别 Taro（`@tarojs/*`）/ uni-app（`@dcloudio/*`），会先问测哪个目标端（小程序 / H5），并按项目 `package.json` 里真实的构建脚本先编译再测——小程序测试指向编译产物目录而非源码根。

依赖：markitdown（脚本自动安装）、Figma MCP（读设计稿，可选）、Chrome MCP 或小程序 MCP（自动化测试，小程序推荐 [weapp-dev-mcp](https://github.com/yfmeii/weapp-dev-mcp)，基于 miniprogram-automator + WebSocket 长连接，复杂项目更抗卡）。各工具的检测/安装/token 获取详见 skill 内 `SKILL.md` 与 `references/`。

产出物统一放在目标项目的 `docs/` 下：`technical-design.md`、`change-log.md`、`code-review.md`、`test-cases.md`、`test-regression.md`。

## 文档模板与任务类型对应

> 由 Step 0 任务类型识别决定（详见 [spec-to-tested-feature/SKILL.md](./spec-to-tested-feature/SKILL.md)）。

| 任务类型 | 必出文档模板 |
|---------|--------------|
| 完整开发任务 | technical-design + change-log + code-review + test-cases + test-regression |
| 纯分析任务 | analysis-report（单份主报告） |
| 运行验证任务 | test-cases + run-verification-report |
| bug 修复任务 | test-cases（复现 + 验收用例） + bug-tracker（状态跟踪表） + test-regression（§6 bug 修复回归章节） |

模板文件均在 `assets/` 目录下，顶部均带「运行通道」必填字段，缺则视为模板不合规。

## 目录约定

```
work-skills/
├── README.md
└── <skill-name>/
    ├── SKILL.md          # 必需：触发条件 + 工作流程
    ├── scripts/          # 可选：可执行脚本
    ├── references/       # 可选：按需加载的参考文档
    ├── assets/           # 可选：模板等产出物素材
    └── commands/         # 可选：Claude Code 斜杠命令（放到 .claude/commands/ 下生效）
```

新增 skill 时，建一个同名目录、写好 `SKILL.md`，并在上面的「skill 列表」表格里补一行。
