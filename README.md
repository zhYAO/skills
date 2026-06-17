# zy-skills

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
| [spec-to-tested-feature](./spec-to-tested-feature) | 需求驱动的端到端开发工作流：解析需求文档 + Figma 设计稿 → 技术文档（人工卡点）→ 开发 → 严格代码 review → 测试用例 → 自动化测试自愈 → 回归文档 | 拿到需求文档/设计稿，需要"从需求到测试一条龙"完成 Web 前端或微信小程序功能开发 |

### spec-to-tested-feature

七阶段、一个人工卡点的开发流水线，跑在支持 MCP 的 coding agent 上：

1. **解析输入** — 用 [markitdown](https://github.com/microsoft/markitdown) 把需求文档（pptx/pdf/docx/md/txt）转成 md（自动检测/安装/验证）；用 Figma MCP 读取设计稿；通读整个项目。
2. **技术文档** —【唯一人工卡点】产出技术设计文档，停下确认需求理解与方案，确认后才开发。
3. **开发** — 按需求 + 设计稿还原 UI，产出代码改动文档。
4. **严格代码 review** — 测试前从需求一致性 / 正确性边界 / 安全 / 项目约定 / 可维护性 / 性能六个维度严查，阻塞级问题当场修复清零，产出审查报告。
5. **测试用例** — 基于验收标准与交互状态产出用例文档。
6. **自动测试 + 自愈** — 自动判定项目类型，Web 前端用 Chrome MCP、微信小程序用小程序 MCP 跑测试，发现问题自动修复重跑（有上限，到限报告不强行标过）。
7. **回归文档** — 产出测试回归文档，结束。

依赖：markitdown（脚本自动安装）、Figma MCP（读设计稿，可选）、Chrome MCP 或小程序 MCP（自动化测试）。

产出物统一放在目标项目的 `docs/` 下：`technical-design.md`、`change-log.md`、`code-review.md`、`test-cases.md`、`test-regression.md`。

## 目录约定

```
zy-skills/
├── README.md
└── <skill-name>/
    ├── SKILL.md          # 必需：触发条件 + 工作流程
    ├── scripts/          # 可选：可执行脚本
    ├── references/       # 可选：按需加载的参考文档
    └── assets/           # 可选：模板等产出物素材
```

新增 skill 时，建一个同名目录、写好 `SKILL.md`，并在上面的「skill 列表」表格里补一行。
