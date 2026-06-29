# CLAUDE.md

本仓库是**个人开发的 skills 仓库**：把工作中沉淀的 coding-agent 工作流打包成可跨 agent 取用的 skill。这里没有应用代码、没有构建/测试命令——**产物是 skill 文档本身（Markdown + 脚本 + 模板）**。在本仓库工作 = 编写、维护、扩展 skill 文件，而不是写业务功能。

---

## 这是什么仓库

- 形态：一个仓库 = 多个独立 skill，每个 skill 是一个**自包含目录**，拷到目标 agent 的 skills 目录即可用。
- 跨 agent：skill 是 LLM 语义层概念，不绑死具体 agent。目标兼容 Claude Code / Trae / Cursor / Codex 等任何支持「Skill 工具 + `context: fork`」的 agent。
- 当前内容：`brd-to-feature/`——需求驱动的端到端开发流水线（7 阶段、2 人工卡点、4 类任务路由）。
- 顶层 `README.md` 是仓库门面（skill 工作原理 + 单元列表 + 目录约定），新增/改动 skill 后**必须同步更新**它。

---

## 目录约定（新增 skill 时严格遵守）

```
zy-skills/
├── README.md                 # 仓库门面：skill 列表 + 目录约定，改 skill 必同步
├── CLAUDE.md                 # 本文件
└── <skill-name>/             # 一个 skill = 一个同名目录
    ├── SKILL.md              # 必需：frontmatter（触发条件）+ 工作流程
    ├── INSTALL.md            # 推荐：跨 agent 安装指引（Claude Code / Trae / Cursor）
    ├── scripts/              # 可选：可执行脚本（agent 调用）
    ├── references/           # 可选：按需加载的参考文档（动手前必看的 guardrails 等）
    ├── assets/               # 可选：产出物模板（*.template.md）
    ├── commands/             # 可选：Claude Code 斜杠命令（拷到 .claude/commands/）
    └── skills/               # 可选：内部 fork 子 skill（隔离上下文跑重活）
        └── <sub-skill>/SKILL.md
```

---

## SKILL.md 写法约定（最关键）

每个 SKILL.md 顶部是 YAML frontmatter，决定 agent 如何加载它。本仓库已有的字段约定：

- `name` — kebab-case，**与目录名一致**。
- `description` — 自然语言触发器。多数 skill 凭它自动匹配加载；要写清「什么场景触发」+「触发词举例」。
- `disable-model-invocation: true` — **主动调用型** skill 用（如 `brd-to-feature`）：不靠自然语言自动加载，必须 `/btf` 斜杠命令或显式点名。容易误触发、代价大的流水线 skill 应该这样设。
- `context: fork` — 内部子 skill 用：在隔离上下文跑，看不到主对话历史，把海量日志/独立审查挡在主上下文外。
- `agent: general-purpose` — 子 skill 指定执行 agent。
- `user-invocable: false` — 内部子 skill 用：只由主流程调用，用户不应直接调。
- `allowed-tools` — 显式列出该 skill 允许的工具，按最小权限给（如代码审查子 skill 只给 `Read Grep Glob Bash(git status *) Bash(git diff *) ...`，确保「只读不改」）。

正文用：动手前必看的 Cardinal rules / 红线、阶段表、人工卡点标记（`🔴 STOP` / `🔴 CHECKPOINT`）、文件地图。详细工作流下沉到 `references/`，按需加载，避免主 SKILL.md 过长。

---

## 命名约定

- 子 skill / 命令 / 脚本统一**带 skill 前缀**避免与 agent 内置冲突。例：`brd-to-feature` 用 `btf-` 前缀（`btf-init`、`btf-code-review`、`/btf`、`/btf-init`——`init` 加前缀以避开内置 `/init`）。
- 模板文件：`<用途>.template.md`，统一放 `assets/`，顶部带「运行通道」必填字段。
- 产出物落在**被测项目**的 `docs/` 下，不落在 skill 仓库里。

---

## 设计原则（沿用 brd-to-feature 的做法）

1. **人工卡点设在最关键处**——需求理解后、测试前各一个 `🔴 STOP`，其余尽量自动化。
2. **不静默降级**——解析失败 / MCP 不可用 / token 缺失 → 直接停 + 给选项，不空跑、不硬产报告。
3. **不替用户假设路径**——编译产物 / cli / 打包命令 / 测试目标端找不到就问，不猜。
4. **自愈有上限**——同一问题修不过 N 次就停、上报，不无限重试也不强标通过。
5. **任务类型路由**——同一 skill 按输入识别任务类型（完整开发/纯分析/运行验证/bug 修复），产对应文档，不一律套同一套。
6. **重活下沉到 fork 子 skill**——通读项目、独立代码审查、跑测试这类「上下文重 / 需要独立视角」的活，拆成 `context: fork` 子 skill。
7. **能 agent 自动装的绝不让用户手装，装不了的明确告诉用户怎么做**（init 脚本的总原则）。

---

## 在本仓库工作时

- 这是文档仓库，**没有 build / lint / test 命令**。改动即 Markdown/脚本编辑。
- 改任何 skill 的结构、触发方式或新增 skill 后，**同步更新顶层 `README.md` 的单元列表表格和目录说明**。
- 改 SKILL.md frontmatter 前，先确认字段语义（见上文「SKILL.md 写法约定」），别破坏 `disable-model-invocation` / `user-invocable` 等触发控制。
- 脚本（`scripts/*.sh`）改完，确保仍是「检测 → 征得同意 → 自动装」的幂等流程，不在用户机器上做破坏性操作。
- 提交信息沿用现有风格：`feat(scope): ...` / `refactor(scope): ...` / `chore: ...` / `docs: ...`，中文描述。
- 不要把被测项目的产出物（technical-design / bug-tracker 等实际生成的文档）提交进本仓库——本仓库只放**模板**。

---

## 快速定位

- 想了解仓库整体 → `README.md`
- 想了解 brd-to-feature 流水线 → `brd-to-feature/SKILL.md`，详细阶段在 `brd-to-feature/references/`
- 想看红线/兜底 → `brd-to-feature/references/guardrails.md`
- 想看跨 agent 安装 → `brd-to-feature/INSTALL.md`
- 想看文档模板长啥样 → `brd-to-feature/assets/*.template.md`
