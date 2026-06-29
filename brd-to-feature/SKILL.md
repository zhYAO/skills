---
name: brd-to-feature
description: 需求驱动的端到端开发流水线（7 阶段、2 人工卡点、4 类任务路由：完整开发/纯分析/运行验证/bug 修复）。把需求文档（+Figma 设计稿）变成已开发且通过自动化测试的功能。用户主动调用：用 /btf 斜杠命令触发，或显式说"用 btf"/"brd-to-feature"。不自动触发——agent 不会仅凭"按需求开发"等自然语言加载本 skill。
disable-model-invocation: true
allowed-tools: Read Edit Write Glob Grep Bash TaskCreate TaskUpdate Skill
---

# brd-to-feature · 工作流

这是一个固定阶段、带两个人工卡点的端到端开发工作流：把一份需求文档（+Figma 设计稿）变成已开发完成、且通过自动化测试的功能，沿途产出对应文档。**文档清单随任务类型而定**（见 Step 0），不要一律套同一套。

**为什么用固定流程**：需求驱动开发最容易翻车的是「需求没对齐就开干」「开发完没验证就交付」。本流程在**需求理解后**和**测试前**各设一个人工卡点，让用户只在最关键处介入，其余尽量自动化。

---

## 🛑 Cardinal rules（速记 · 完整 15 条见 `references/guardrails.md`）

1. **先 init 再 /btf** — 工具未装好就跑需求 = 一路红。详见 `commands/btf-init.md`。
2. **卡点 1 未确认不开工、卡点 2 未放行不测试** — 🔴 STOP。卡点存在的意义就是等用户点头。
3. **不替用户假设路径** — 编译产物路径 / IDE cli 路径 / 打包命令 / 测试目标端，找不到就问，不要猜。
4. **不静默降级** — 解析失败、MCP 不可用、token 缺失时直接 🔴 STOP + 给选项，不空跑、不硬产报告。
5. **自愈有上限** — 同一 bug 同一用例 3 次修不过 → 停自愈、上报用户，不无限重试也不强标通过。
6. **文档清单匹配任务类型** — 完整开发 / 纯分析 / 运行验证 / bug 修复各产各的，硬套 = 红名单 #12。

---

## 🗂 Step 0 · 任务类型路由（必做）

进入主流程前必须识别任务类型，**不允许擅自假定**。

| 类型 | 触发词举例 | 文档清单 |
|------|-----------|----------|
| **完整开发任务** | "按需求做这个功能"、"实现这个页面" | technical-design + change-log + code-review + test-cases + test-regression |
| **纯分析任务** | "性能分析"、"代码审计"、"安全扫描" | 1 份主报告（`docs/{scope}-report.md`） |
| **运行验证任务** | "跑一下回归"、"对比设计稿" | test-cases + run-verification-report |
| **bug 修复任务** | "修这个 bug"、"这个报错怎么解决" | test-cases + bug-tracker + test-regression |

**识别规则**：带需求文档 → 完整开发；项目路径 + 抽象动词（分析/审计/扫描）→ 纯分析；已有代码 + 跑测试/截图 → 运行验证；bug 描述/报错日志 → bug 修复。仍不确定 → `AskUserQuestion`。**bug 修复的硬约定**（4 条速记，完整见 stages.md §变体）：先复现 → 登记 tracker → 修复后回归 → 用户验收才 `closed`。

---

## 🔁 七阶段（完整开发任务 · 详情见 references）

| 阶段 | 关键动作 | 产物 / 子 skill | 详情 |
|------|----------|----------------|------|
| 1 · 解析输入 | markitdown 转需求 / Figma MCP 读设计稿 / 子 skill 通读项目 | `docs/requirements.md`、`docs/project-survey.md` | `references/stages.md` §1 |
| 2 · 技术文档 | 用 `assets/technical-design.template.md` 写技术设计 | `docs/technical-design.md` → 🔴 **卡点 1** | `references/stages.md` §2 |
| 3 · 开发 | 严格按文档 + 设计稿实现 + git 辅助列改动 | `docs/change-log.md` | `references/stages.md` §3 |
| 4 · 严格 review | 子 skill 隔离审查（6 维度）+ 主上下文修阻塞项 | `docs/code-review.md` → 🔴 **卡点 2** | `references/stages.md` §4 |
| 5 · 测试用例 | 覆盖正常/边界/异常 + 设计稿状态 | `docs/test-cases.md` | `references/stages.md` §5 |
| 6 · 自动测试 + 自愈 | 判定项目类型 → 编译前置 → IDE/MCP 自检 → 委派子 skill | `docs/bug-tracker.md`、可能 `docs/test-run.md` | `references/build-and-test.md` |
| 7 · 回归文档 | 总结测试范围、结果、自愈记录、bug 状态 | `docs/test-regression.md` | `references/stages.md` §7 |

开始前用 `TaskCreate` 把 7 阶段登记成任务，逐阶段标记完成。所有文档统一放被测项目的 `docs/`。

---

## 🔄 关键卡点（详见 `references/stages.md`）

- **🔴 卡点 1 · 技术文档后** — 未拿到用户对需求理解与技术方案的明确同意前禁止开发。完整询问模板见 stages.md §2。
- **🔴 卡点 2 · 代码审查后** — 未拿到用户对「是否改代码 / 是否做截图比对」的明确放行前禁止测试。完整询问模板见 stages.md §4 末尾。

---

## 📦 内部子 skill（仅主流程调用 · `user-invocable: false`）

- `btf-explore-project` — 阶段 1c fork 子任务：隔离上下文只读通读项目，写 `<项目根>/docs/project-survey.md`。
- `btf-code-review` — 阶段 4 fork 子任务：隔离上下文只评不改 6 维度审查，写 `<项目根>/docs/code-review.md`。
- `btf-run-tests` — 阶段 6 fork 子任务：隔离上下文跑测试 + 自愈 + 维护 bug-tracker，海量日志挡在子任务里。

三个子任务都接收**被测项目根目录的绝对路径**作为参数，产物统一落在该项目 `docs/`。环境不支持 `context: fork` 时，对应阶段退化为主上下文内联执行。

---

## 📁 文件地图

| 目录 | 用途 |
|------|------|
| `assets/*.template.md` | 8 份文档模板（technical-design / change-log / code-review / test-cases / test-regression / bug-tracker / analysis-report / run-verification-report） |
| `references/guardrails.md` | 15 条红线 + 失败兜底速查表，每阶段动手前必看 |
| `references/figma.md` | Figma MCP 读设计稿方法 |
| `references/stages.md` | 阶段 1-5, 7 详细工作流 + 变体任务路径 |
| `references/build-and-test.md` | 阶段 6 详细工作流（运行时观测判定门 / 项目类型判定 / 编译前置 / IDE 自检 / 委派子 skill / 接子任务结果）|
| `references/web-testing.md` | Chrome MCP 测试 Web 前端 |
| `references/miniprogram-testing.md` | 小程序 MCP 测试 + IDE 启动 + 4 档重试退避表 |
| `scripts/btf-init.sh`、`scripts/ensure_markitdown.sh` | btf-init 时跑的环境检测 / markitdown 装脚本 |
| `commands/btf-init.md` | `/btf-init` 斜杠命令（工具初始化） |
| `commands/btf.md` | `/btf` 斜杠命令（主流程入口） |
| `INSTALL.md` | 跨 agent 安装指引（Claude Code / Trae / Cursor） |

---

## 🚀 主动调用方式

- **斜杠命令**：Claude Code 输入 `/btf`（详见 `commands/btf.md`）。
- **自然语言**：显式说「用 btf 做这个需求」「brd-to-feature」也可触发。
- **不自动触发**：本 skill `disable-model-invocation: true`，说「按需求开发这个功能」不会自动加载——必须显式点名 btf。

工具未初始化？先跑 `/btf-init`（详见 `commands/btf-init.md`）。安装 / 跨 agent 部署？读 `INSTALL.md`。
