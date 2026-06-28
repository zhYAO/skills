---
name: brd-to-feature
description: 当用户提供一份需求文档（pptx/md/txt/pdf/docx 等）和/或一份 Figma 设计稿，希望"按需求和设计稿把功能开发出来并测试通过"时使用本 skill。它把"解析需求 → 技术文档（人工卡点）→ 开发 → 代码审查 → 测试用例 → 自动化测试自愈 → 回归文档"固化成一条流水线，测试用 Chrome MCP（Web 前端）或小程序 MCP（微信小程序）。只要用户提到"按需求文档开发""照着设计稿做""完整开发流程""从需求到测试一条龙""parse requirements and build""implement from Figma"之类，即使没逐字点名本 skill，也应触发它。
allowed-tools: Read Edit Write Glob Grep Bash TaskCreate TaskUpdate Skill
---

# BRD-to-Feature 工作流

这是一个固定阶段、带两个人工卡点的端到端开发工作流。目标：把一份需求文档（和可选的 Figma 设计稿）变成已开发完成、且通过自动化测试的功能，并沿途产出对应的文档。**文档清单随任务类型而定**（完整开发 / 纯分析 / 运行验证 / bug 修复，见下方 Step 0），不要一律套同一套。

为什么用固定流程：需求驱动开发最容易出问题的地方是"需求没对齐就开干"和"开发完没验证就交付"。本流程设两个人工卡点——**卡点 1**在需求理解后（技术文档确认），**卡点 2**在开发+代码审查后、测试前（确认是否改代码、是否做设计稿截图比对），其余阶段尽量自动化，让人只在最关键处介入。

## 适用环境

- 运行在 Claude Code / Cursor / Trae 等支持 MCP 的 coding agent 中。
- 测试目标：Web 前端（用 Chrome MCP）或微信小程序（用小程序 MCP）。跨端框架（Taro / uni-app）按用户选定的目标端编译后再测。在阶段 6 自动判定项目类型后选择。
- 设计稿：通过 Figma MCP 读取（若提供了设计稿链接/文件 key）。

---

## btf-init 命令：初始化所需工具

当用户说 **`btf-init`** / **初始化环境** / **装一下这个插件需要的工具** 时，**只做环境准备，不解析任何需求、不开发**。目标：把本插件依赖的工具一次性检测、给出获取指引（含 token / 环境变量怎么设），让后续正式流程能顺畅跑。

（命令名用 `btf-init` 而非 `init`，避免和 Claude Code 内置的 `/init` 命令冲突。）

> **插件已内置 MCP 声明**：Figma（`figma` / Framelink）与小程序（`weapp-dev`）两个 MCP server 已在插件 `.mcp.json` 里声明，安装插件即注册——**不需要再手改用户的 MCP 配置**。btf-init 要做的是检测工具是否就绪、并指导用户补齐运行所需的环境变量与外部前置（token、开发者工具、浏览器扩展）。

运行方式：执行 `bash scripts/btf-init.sh` 做一轮自动检测，它会打印每个工具的状态（OK / 缺失）。然后按下面的清单逐项处理。**原则：能命令行自动装的（如 markitdown）先征得用户同意再装；只能人工做的（环境变量、token、浏览器扩展、启动开发者工具），给清晰步骤和获取链接，不要假装能代办。**

逐项处理：

1. **markitdown（必需）** — 跑 `bash scripts/ensure_markitdown.sh`，它自动检测→安装→验证。失败则把报错和手动命令给用户。
2. **小程序 MCP（测微信小程序需要）** — server 已由插件 `.mcp.json` 声明（`weapp-dev`，走 `npx -y @yfme/weapp-dev-mcp`）。检测工具列表里有没有 `mp_*` / `page_*` / `element_*`。若没有，多半是**没设环境变量或没启开发者工具**：指导用户设 `WEAPP_WS_ENDPOINT`（如 `ws://localhost:9420`），并按 `references/miniprogram-testing.md` 启动微信开发者工具、开启自动化端口（需 Node.js 18+）。**不要去改 MCP 配置**——只补环境变量与前置。
3. **Figma MCP（按设计稿开发需要）** — server 已由插件 `.mcp.json` 声明（`figma` / Framelink，走 `npx -y figma-developer-mcp --stdio`）。检测工具列表里有没有 `figma` 工具。若没有，多半是**没设 `FIGMA_API_KEY`**：明确告诉用户 token 获取路径：Figma → `Settings` → `Security` → `Personal access tokens` → 生成，权限至少给 File content 读取；把它设到环境变量 `FIGMA_API_KEY`（别提交进仓库或打日志），重载 MCP 即可。详见 `references/figma.md`。
4. **Chrome MCP（测 Web 前端需要）** — 检测有没有 `mcp__*Chrome*` 之类工具。这个**只能人工**：引导用户装浏览器扩展并授权连接（见 `references/web-testing.md`）。插件不声明它（浏览器扩展不走 `.mcp.json`）。

处理完后，给用户一份小结：哪些已就绪、哪些待用户操作（附下一步动作）、哪些本次用不到可跳过。**init 到此结束，不要顺势开始解析需求或开发**——正式流程由用户后续单独发起。

按需选择：如果用户明确只做某一类项目（比如只测小程序），其余 MCP 可以标注"本项目用不到"，不必强求设齐。

> 关于内部子代理：本插件自带三个内部子代理（`btf-explore-project`、`btf-code-review`、`btf-run-tests`，放在插件 `agents/` 下，随插件一起安装、无需额外配置或 token），只由主流程在阶段 1c/4/6 用 Task 调用，用户不直接触发。btf-init 无需为它们做任何事，提一句让用户知道即可。

---

## Step 0：识别任务类型（必做）

进入主流程前必须识别任务类型，三种走法对应不同文档清单。**不允许擅自假定**——纯分析任务跑完整 7 阶段会产出臃肿且不匹配的文档。

| 类型 | 触发词 | 文档清单 |
|------|--------|----------|
| **完整开发任务** | "按需求做这个功能"、"实现这个页面"、"开发并测试" | 5 份：technical-design + change-log + code-review + test-cases + test-regression |
| **纯分析任务** | "性能分析"、"代码审计"、"安全扫描"、"看这个项目有什么问题" | 1 份主报告（如 `docs/{scope}-report.md`） |
| **运行验证任务** | "跑一下回归测试"、"对比设计稿"、"截图比对" | 2 份：test-cases + test-regression |
| **bug 修复任务** | "修这个 bug"、"这个报错怎么解决"、"程序出问题了"、"case 失败了修一下"、"上线后用户反馈 XX" | 3 份：test-cases（复现 + 验收用例） + bug-tracker（状态跟踪表） + test-regression（回归含 bug 验证章节） |

**识别方式**：若用户提供了需求文档 → 默认走完整任务；若是项目路径 + 抽象动词（分析/审计/扫描/优化）→ 走纯分析任务；若是已有代码 + 跑测试/截图 → 走运行验证任务；若是 bug 描述 / 报错日志 / "修了又出现"等 → 走 bug 修复任务。仍不确定时用 AskUserQuestion 问用户。

**bug 修复任务的关键约定**：
1. **必须先复现**：进入流程后第一件事是写"复现用例"（TC-bug-XXX）放 test-cases.md，没复现不进入修复——避免修了半天是误报。
2. **必须登记 bug**：每个 bug 在 `docs/bug-tracker.md` 占一行（即使只有一个），状态从 `open` 起步。
3. **修复后必须回归**：状态 `fixed` 后必须跑 bug-tracker.md 第 7 节定义的"防回归重跑列表"，全绿才能改 `verified`。
4. **回归测试后必须 closed**：用户验收（人工或自动）通过后状态 `closed`，未通过的回到 `in_progress`。

### 变体任务怎么走（非完整开发任务）

下面三类任务**不走完整七阶段**，按各自的精简路径走，只产出对应文档（硬套七阶段 = 红名单 #12）：

- **纯分析任务**（性能分析 / 代码审计 / 安全扫描）：① 阶段 1（解析输入 + 阶段 1c 通读项目，委派 `btf-explore-project`）→ ② 按分析主题逐项排查并取证（性能要实测、审计要逐文件）→ ③ 用 `assets/analysis-report.template.md` 产出**一份主报告** `docs/{scope}-report.md`（如 `performance-report.md`）。无开发、无卡点、无测试。
- **运行验证任务**（跑回归 / 设计稿截图比对）：① 阶段 1c 通读项目（如需）→ ② 阶段 5 写/复用测试用例 → ③ 阶段 6 执行测试 + 自愈 → ④ 用 `assets/run-verification-report.template.md` 产出 `docs/run-verification-report.md`。无技术文档、无卡点 1（直接进测试）。
- **bug 修复任务**：① **先复现**（阶段 5 写 TC-bug-XXX 复现用例）→ ② 登记 `docs/bug-tracker.md`（状态 `open`）→ ③ 定位修复（阶段 3 改动 + change-log）→ ④ 阶段 4 审查（委派 `btf-code-review`）→ ⑤ 阶段 6 回归 + bug 状态机推进 → ⑥ 阶段 7 回归文档（含 bug 修复章节）。产出 test-cases + bug-tracker + test-regression 三份。

完整开发任务才走下面完整的七阶段。

---

## 总览：七个阶段（完整开发任务）

1. **解析输入** — 需求文档 → md（markitdown）；设计稿 → 结构与样式（Figma MCP）；阅读整个项目。
2. **技术文档** — 产出 `docs/technical-design.md` → **【人工卡点 1】** 询问是否需要修改需求/方案，确认后才继续。
3. **开发** — 按需求 + 设计稿实现；完成后产出 `docs/change-log.md`（改动文件清单与说明）。
4. **严格代码 review** — 对本次改动做严格代码审查，发现问题先修复，产出 `docs/code-review.md` → **【人工卡点 2】** 测试前询问是否改代码、是否做开发页面与设计稿的截图比对，放行后才测试。
5. **测试用例** — 产出 `docs/test-cases.md`。
6. **自动测试 + 自愈** — 判定项目类型，用 Chrome MCP / 小程序 MCP 跑测试；发现问题自动修复并重跑，直到通过或确认无法自动解决。
7. **回归文档** — 产出 `docs/test-regression.md`，结束流程。

开始前，先用任务列表（TaskCreate）把这七个阶段登记成任务，逐阶段标记完成，让用户看到进度。所有文档统一放在项目的 `docs/` 目录下。

---

## 阶段 1：解析输入

### 1a. 解析需求文档（markitdown）

用户会提供一份或多份需求文档（pptx/pdf/docx/md/txt 等）。统一用 [markitdown](https://github.com/microsoft/markitdown) 转成 md，便于后续阅读与引用。

**确保 markitdown 可用**：若 btf-init 阶段已装好则直接用；否则跑 `bash scripts/ensure_markitdown.sh`（它封装了检测→安装→复检：优先 `pipx install markitdown`，失败回退 `pip install 'markitdown[all]' --break-system-packages`，验证不过会非零退出并打印原因）。**安装失败不要静默继续**——告诉用户失败原因并停下来，因为后续步骤依赖解析结果。

转换：

```bash
markitdown "<需求文档路径>" -o docs/requirements.md
```

如果是 md/txt，可直接拷贝/读取，无需转换。多份文档分别转换后合并到 `docs/requirements.md`，并保留每段的来源标注。

**注意扫描件/图片型 PDF**：如果解析结果明显为空、只有零星字符或一堆乱码，多半是扫描件或截图拼成的 PDF（整页其实是图片，里面没有可提取的文字）。这种情况 markitdown 提不出内容，要提示用户："这份 PDF 像是扫描件/图片，无法直接提取文字，需要 OCR（图片文字识别）或由你提供文字版需求。"不要拿空内容硬往下走。

### 1b. 读取设计稿（Figma MCP）

如果用户提供了 Figma 设计稿（链接或 file key），用 Figma MCP 读取，作为开发还原 UI 的依据。读取设计稿前先确认 Figma MCP 是否已连接：

- 列出可用工具，找名字里含 `figma` 的 MCP 工具（常见能力：获取文件节点树、读取某个 frame/组件的布局与样式、导出图片、拿设计 token/变量）。
- 若工具列表里没有 `figma` 工具：server 已由插件 `.mcp.json` 声明（Framelink），通常只是**还没设 `FIGMA_API_KEY`**——指导用户设好环境变量、重载 MCP 即可（token 获取见 `references/figma.md`），不必手改 MCP 配置；用户若明确说没有设计稿，可跳过、仅按需求文档开发。不要假装能看到设计稿。

读取到设计稿后，把关键信息沉淀进技术文档（阶段 2）：涉及的页面/组件清单、布局结构、间距与栅格、配色与字体 token、关键交互状态（hover/active/disabled/空态/加载/错误）、以及与现有项目组件的对应关系。开发时（阶段 3）严格对照这些还原，而不是凭印象画 UI。

详见 `references/figma.md`。

### 1c. 阅读整个项目（委派给子代理）

解析完输入后，通读项目、建立全局认知再动手。**这一步委派给内部子代理 `btf-explore-project` 执行**——它在隔离上下文里只读地通读项目，把几十个文件的原文挡在主上下文之外，只回传摘要，从而避免污染主流程上下文。

调用方式：用 Task 工具调用子代理 `btf-explore-project`（`subagent_type: "btf-explore-project"`），**prompt 里传被分析项目根目录的绝对路径**（子代理在隔离上下文里没有主对话的工作目录，必须靠这个绝对路径定位）。它会：

- 在隔离上下文里读清技术栈/框架（含是否 Taro / uni-app 跨端框架）、目录结构、组件库与设计 token、代码风格与约定、现有测试方式；
- 把完整结论写到 **`<项目根>/docs/project-survey.md`**（写在项目自己的 `docs/` 下，用户能直接看到）；
- 回传一段摘要（框架与目标端、可复用组件/token、必须遵守的约定、测试方式、风险点），末尾附写盘绝对路径。

子任务返回后，主流程**读取 `<项目根>/docs/project-survey.md`** 作为阶段 2 写技术文档的依据。目的始终是让后续改动**贴合现有约定**、做外科手术式小改动，而不是引入与项目格格不入的新模式。

> 注：`btf-explore-project` 是本插件的内部子代理（定义在 `agents/btf-explore-project.md`），只由本主流程用 Task 调用，用户不直接触发。若运行环境不支持子代理，退化为在主上下文里按上面 6 点自行通读项目即可。

---

## 阶段 2：技术文档 + 🔴【人工卡点 1】

基于需求 md、设计稿、项目现状，产出技术设计文档。用 `assets/technical-design.template.md` 作为骨架，写到 `docs/technical-design.md`。

文档应覆盖：需求理解与范围、设计稿还原要点（页面/组件/交互状态）、技术方案与涉及模块、数据结构/接口、改动计划（要新增/修改哪些文件）、风险与未决问题、验收标准。

写完后是流程的第一个人工卡点。

> 🔴 **CHECKPOINT 1 · 🛑 STOP** — 未得到用户明确同意前，禁止进入开发阶段。

停下来，明确询问用户：

> 技术设计文档已生成（docs/technical-design.md）。请确认：
> 1. 我对需求的理解是否准确？需不需要修改需求文档？
> 2. 技术方案/设计稿还原要点是否同意？
> 确认后我再开始开发。

如果用户要求修改需求或方案，更新 `docs/requirements.md` / `docs/technical-design.md` 后**再次确认**，直到用户明确同意。未得到明确同意前不要进入开发阶段——这正是卡点存在的意义。

---

## 阶段 3：开发 + 改动文档

得到确认后开始开发。原则：

- 严格按已确认的技术文档和设计稿实现，遇到文档未覆盖的细节，优先沿用项目既有约定。
- 对照 Figma 设计稿还原 UI：布局、间距、配色、字体、交互状态都要核对，尽量复用项目已有组件与 token，不要硬编码与设计稿不符的样式。
- 做最小必要改动，避免顺手重构无关代码。

开发完成后，产出代码改动文档 `docs/change-log.md`（用 `assets/change-log.template.md`）。列出所有改动文件，每个文件说明改了什么、为什么改。用 git 辅助生成清单：

```bash
git status            # 完整文件清单：含修改、删除，以及 Untracked files（新增文件）
git diff HEAD --stat  # 已跟踪文件改动的概览
```

`git status` 给出全部受影响文件（新文件会列在 Untracked 区）；`git diff HEAD` 显示已跟踪文件的具体改动，新文件的内容直接读文件本身即可。不要为了凑 diff 去 `git add`，以免污染暂存区。把这些落进改动文档，并对每个文件补一句话说明意图。

---

## 阶段 4：严格代码 review

进入测试之前，**必须**对本次改动做一次严格的代码审查。原因：自动化测试只能覆盖被测路径，很多问题（安全、可维护性、边界遗漏、与项目约定不一致）测试发现不了，越早在测试前拦住成本越低。

### 4a. 审查（委派给子代理）

审查动作**委派给内部子代理 `btf-code-review` 执行**——它在隔离上下文里，用一双不被开发过程带偏的眼睛重新读 diff，既获得「第二双眼睛」的客观性，又把大量 diff 内容挡在主上下文之外。

调用方式：用 Task 工具调用子代理 `btf-code-review`（`subagent_type: "btf-code-review"`），**prompt 里传被审查项目根目录的绝对路径**与 `docs/technical-design.md` 路径（供它对照需求一致性；隔离上下文需绝对路径定位）。它会：

- `git status` + `git diff HEAD` 拿到本次改动（含新增文件），逐文件按六维度（需求与设计一致性 / 正确性与边界 / 安全 / 项目约定一致性 / 可维护性 / 性能）严格核对；
- 把结论按 `assets/code-review.template.md` 写到 **`<项目根>/docs/code-review.md`**（写在项目自己的 `docs/` 下，用户能直接看到）；
- 回传分级问题摘要——**先列阻塞级**（文件:行、问题、建议改法），再列建议级，最后给「是否存在阻塞项」的总体结论，附写盘绝对路径。

> 注：`btf-code-review` 是本插件的内部子代理（定义在 `agents/btf-code-review.md`），只由本主流程用 Task 调用，用户不直接触发。它**只评不改**。若运行环境不支持子代理，退化为在主上下文里自己按上述六维度逐文件核对。

### 4b. 按分级处理（在主上下文执行修复）

拿到子任务回传的问题清单后，**修复在主上下文里做**（这样改动可见、可进卡点 2 复核）：

- 阻塞级（bug、安全问题、需求未实现、严重不符约定）→ **当场修复**，修复后重新核对相关部分（必要时再调一次 `btf-code-review`），并把改动同步进 `docs/change-log.md`，同时更新 `docs/code-review.md` 的「已修复项」。
- 建议级（可优化但不阻塞）→ 保留在 `docs/code-review.md` 里，由用户决定是否处理。

只有阻塞级问题全部清零后，才到下面的测试前卡点。

### 🔴 测试前卡点【人工卡点 2】

代码审查完成、阻塞问题清零后，进入测试前停下来，这是流程的第二个、也是最后一个人工卡点。

> 🔴 **CHECKPOINT 2 · 🛑 STOP** — 未得到用户明确放行前，禁止开始测试。

原因：开发刚结束、还没测，是用户调整代码或追加要求成本最低的时机；同时设计稿还原是否到位，最好让用户也看一眼再决定怎么测。

向用户汇报代码审查结论（指向 `docs/code-review.md`），并明确询问两件事：

> 开发与代码审查已完成（docs/code-review.md）。进入测试前请确认：
> 1. **是否还要修改代码？**（比如审查里的建议级问题、你新发现的点）需要的话我先改，改完更新改动文档再测。
> 2. **是否要把开发后的页面和 Figma 设计稿做截图比对？** 如果要，我会对照设计稿截取关键页面/组件并与设计稿并排比对，把还原差异列出来。

按用户回答处理：

- 要改代码 → 改完后同步更新 `docs/change-log.md`，并对改动重新做一次相关的代码审查，再回到本卡点确认，直到用户放行。
- 要截图比对 → 用对应的测试通道截图（Web 用 Chrome MCP、小程序用 `mp_screenshot`），用 Figma MCP 导出对应节点图片，并排核对布局/间距/配色/字号，把差异清单给用户；用户确认差异可接受或修复后，再继续。
- 用户放行后才进入测试阶段。未得到明确放行前不要开始测试。

如果本次没有 Figma 设计稿，第 2 问可跳过或注明"无设计稿，略"。

---

## 阶段 5：测试用例

基于需求验收标准 + 设计稿交互状态，写测试用例到 `docs/test-cases.md`（用 `assets/test-cases.template.md`）。

每条用例包含：编号、对应需求点、前置条件、操作步骤、预期结果、类型（功能/UI 还原/边界/异常）。覆盖正常路径、边界、异常、以及设计稿里定义的各种状态（空态/加载/错误/禁用）。这份用例既是测试依据，也是阶段 6 自动执行的脚本来源。

---

## 阶段 6：自动测试 + 自愈修复

### 6a. 判定项目类型与测试目标

按以下顺序判定，**先看跨端框架，再看原生类型**——因为 Taro / uni-app 这类框架会带 `project.config.json`，容易被误判成原生小程序。

1. **跨端框架（Taro / uni-app 等）**：看 `package.json` 的 `dependencies`/`devDependencies`——含 `@tarojs/*` 即 Taro，含 `@dcloudio/*` 即 uni-app。这类一套代码可编多端（微信小程序 / H5 等），**`src/` 源码本身不能直接跑或被小程序工具打开**，必须先编译。识别为跨端框架后：
   - **问用户这次要测哪个目标端**（微信小程序 / H5）。不要替用户假设。
   - 选小程序 → 走小程序 MCP（见 6a-编译前置）；选 H5 → 走 Chrome MCP。
2. **原生微信小程序**：根目录有 `project.config.json` / `app.json` 且 `src` 或根目录直接是小程序结构（`pages/`、`app.js`、`app.json`），且 `package.json` 没有上面的跨端依赖 → 用小程序 MCP，项目路径就是项目根。
3. **Web 前端**：有 `index.html` + `vite`/`webpack`/`next` 等配置、`public/` → 用 Chrome MCP。
4. 仍不确定时，询问用户以哪个为准。

#### 6a-编译前置（跨端框架必做，但**优先复用用户已有的产物**）

跨端框架（如 Taro / uni-app）的源码要先编译成目标端产物才能测。**核心原则：能不重新编译就不重新编译；不知道路径就不要猜。**

按以下顺序处理：

1. **先询问用户是否有现成编译产物**（**优先路径，能省 5+ 分钟**）：
   > 这个项目是否已经有编译产物？如果有，请提供编译产物目录的绝对路径（小程序一般是 `<项目根>/dist/<target>` 或类似子目录，但**以你项目实际为准**）。我直接让小程序 MCP 打开它。
   
   若用户提供路径 → 直接跳到 §6a-3 校验目录，跳过 §6a-2 编译步骤。

2. **若无产物，再询问如何编译**（**不猜**）：
   - 读 `package.json` 的 `scripts` 字段（**仅作为与用户讨论时的参考，不擅自执行**）：
     ```bash
     cat package.json   # 看 scripts，找类似 build:weapp / dev:weapp / build:h5 / dev:h5 的项
     ```
   - **先问用户**：
     > 我看到 scripts 里可能有 `build:weapp` / `dev:weapp` / 自定义命令，你希望我怎么编译？
     > - 你来手动跑并把产物路径告诉我
     > - 还是授权我跑其中一个命令（**请明确告诉我跑哪个**）
     > - 或者项目用自定义构建，需要你给步骤
   - **禁止猜测**：不擅自跑未确认的命令、不假设产物目录、不假设构建工具版本。

3. **校验产物目录**（用户给路径之后）：
   - 必须含 `app.js` + `app.json`（或 `project.config.json`）
   - 若目录不完整 → 把缺的项告诉用户，请用户确认是否给的是正确路径，**不要重新猜测**

**目标端与产物路径映射**（**仅作参考，最终以用户提供的为准**）：
- Taro 微信小程序产物：常见 `<项目根>/dist/weapp-prod` / `dist/weapp-staging` / `dist/weapp-dev`，也可能被 `config/` 改过
- uni-app 微信小程序产物：常见 `<项目根>/unpackage/dist/dev/mp-weixin` 或 `dist/build/mp-weixin`

**小程序 MCP（开发者工具 `--project`）必须指向编译产物目录，不是 `src/` 源码根**——这是硬性约束，无论产物是用户给的还是 agent 编译的。

**测 H5**（如用户选 H5 而非小程序）：跑项目里实际的 H5 启动脚本（常见 `npm run dev:h5`），拿到本地 URL 再走 Chrome MCP——同样**先问用户哪个脚本**。

原生小程序 / 普通 Web 前端无需此步。

### 6b-前置：IDE 启动 + MCP 就绪自检（小程序测试必做）

测小程序前必须确认开发者工具已启动、自动化端口已开、小程序 MCP 已稳定连接，**否则不准开测**。完整自检步骤（cli 路径探测、启动命令、45 秒等待、三项探测、4 档重试退避表、STOP 信号）见 `references/miniprogram-testing.md` 的「IDE 启动 + MCP 就绪自检」。

要点（细节以 reference 为准）：cli 路径**找不到就问、不要猜**；产物目录用 §6a 已确定的、**不要重新猜测**；首次启动 **sleep ≥ 45 秒**别过早重连；连接先 `mp_listProjects` 再 `mp_ensureConnection`；4 次重试全败 → 🔴 STOP 上报用户（见 guardrails.md #11）。原生 Web 前端无此步。

### 6b + 6c. 执行测试 + 自愈（委派给子代理）

**前置交互全部由主流程在 6a / 6a-编译前置 / 6b-前置 完成后**（项目类型已定、目标端已问、编译产物已确认、IDE/测试 MCP 已连上），把「逐条跑用例 + 自愈修复 + 维护 bug-tracker」这段**重活委派给内部子代理 `btf-run-tests`**——测试会产生海量 console/network 日志，由它在隔离上下文里消化，只回传通过情况与最终 bug 状态，避免污染主流程上下文；自愈是自动循环，子代理不与用户交互（不使用 `AskUserQuestion`）。

调用方式：用 Task 工具调用子代理 `btf-run-tests`（`subagent_type: "btf-run-tests"`），prompt 里传：**被测项目根目录的绝对路径**、**测试通道**（`chrome` / `miniprogram`）、**测试用例文件路径**（`<项目根>/docs/test-cases.md`）、**可运行入口**（Web 的本地 URL / 小程序已连接的开发者工具）、**任务类型**。它会：

- 逐条执行用例并断言（Web 用 Chrome MCP，小程序用小程序 MCP；UI 还原类对照 Figma 核对视觉）；
- 发现问题自动修复，在 `<项目根>/docs/bug-tracker.md` 走 bug 状态机（`open→in_progress→fixed→verified→closed`，对齐 `assets/bug-tracker.template.md`），改代码同步 `docs/change-log.md`；
- 同一项修 3 次不过就停止该项自愈、标「需用户决定」；
- 回传摘要：用例通过/失败/阻塞数、未关闭 bug 清单、**需介入事项（⚠️）**、写盘绝对路径。

> 注：`btf-run-tests` 是本插件的内部子代理（定义在 `agents/btf-run-tests.md`），只由主流程用 Task 调用。它**不能问用户、不连/不装 MCP、不启 IDE、不替用户假设目标端或降级**——遇到这些会回报主流程。若环境不支持子代理，退化为主流程在主上下文里按子代理描述的步骤自己跑。

### 6d. 接子任务结果（在主上下文处理需用户介入的事项）

子任务返回后，主流程负责所有「需要用户」的收尾：

- **回传里有 ⚠️ MCP 未连接 / 环境不可用** → 按 guardrails.md #11 向用户给选项（等待恢复 / 降级到静态分析并在产物标「运行通道 ⚠️ 仅静态分析」/ 取消），**绝不静默降级硬产报告**。
- **有 ⚠️ 3 次未修好的 bug** → 把现象/已试修复/推测原因报给用户决定（对应 guardrails.md #9）。
- **有待 `closed` 的 bug** → `verified` 升 `closed` 需用户验收/上线确认，由主流程在卡点或收尾时与用户确认。
- 全绿且无 ⚠️ → 直接进阶段 7。

> **防回归门槛**：所有用例最终全绿、且无未关闭阻塞 bug，才进阶段 7。若子任务回报仍有 `open`/`in_progress`/未升 `verified` 的 bug，处理完再继续。

---

## 阶段 7：测试回归文档

测试全部通过（或明确记录了无法自动解决的项）后，产出回归文档 `docs/test-regression.md`（用 `assets/test-regression.template.md`）：

- 测试范围与环境（项目类型、所用 MCP、被测版本/commit）。
- 每条用例的执行结果（通过/失败/阻塞）。
- 自愈循环记录：发现的问题、根因、修复方式、复测结果。
- 设计稿还原核对结论。
- 遗留问题与建议。

**bug 修复任务的额外章节**（如本次为 bug 修复任务，§6 必须包含）：
- **§6. bug 修复回归**：引用 `docs/bug-tracker.md`，列出本次会话所有 bug 的最终状态（必须全部 `closed` / `verified` / `wontfix` 才能完成回归）。每条 bug 至少记录：状态最终值、复测结果、关联 commit。
- **§6.1 防回归重跑记录**：列出 `btf-run-tests` 防回归重跑（动了共用逻辑后重跑相关用例）的结果，可引用其回传摘要与 `docs/test-run.md`。
- **§6.2 未关闭 bug**：如有未关闭（`open` / `in_progress` / `fixed` 未升 `verified`）的 bug，**禁止完成本次回归**——必须先回到阶段 6 处理。

**产出后向用户汇报整体结果，结束流程**。用可用的文件呈现工具（如 `present_files` / `mcp__cowork__present_files`，工具名随运行环境而定；没有就直接告知用户文档在项目 `docs/` 下的路径）按任务类型提供文档：

| 任务类型 | 提供给用户的文档 |
|---------|-------------------|
| 完整开发任务 | technical-design + change-log + code-review + test-cases + test-regression |
| 纯分析任务 | 主报告（如 `performance-optimization.md`） |
| 运行验证任务 | test-cases + run-verification-report（或 test-regression） |
| bug 修复任务 | test-cases + bug-tracker + test-regression |

---

## 🚫 红线与失败兜底 → 见 `references/guardrails.md`

两张关键速查表（**红灯黑名单** 14 条 + **失败兜底速查表**）已外移到 `references/guardrails.md`，以减小本文件常驻上下文。**强制要求：每个阶段动手前先过一遍 `references/guardrails.md` 的红灯黑名单；遇到任何失败按其失败兜底表处理。** 任一红线命中 → 🔴 STOP 纠正，绝不静默跳过、绝不空跑。

最容易翻车、必须随时记牢的几条（完整清单仍以 guardrails.md 为准）：

- 卡点 1 未确认就开发、卡点 2 未放行就测试 —— 🔴 STOP。
- 工具/扩展/token 假装能代办；解析失败/MCP 不可用时静默降级硬产出。
- 猜测编译产物路径 / IDE 路径 / 打包命令；用户未授权就跑构建。
- 自愈循环无限重试或强行标记通过（同一项 3 次不过就上报）。
- 任务类型与文档清单不匹配（硬套完整开发的 5 份）。

---

## 文档产出物一览

所有文档统一放被分析项目的 `docs/` 下。**按任务类型只产出对应文档**（见 Step 0）：

| 文档 | 模板 | 哪些任务产出 |
|------|------|-------------|
| docs/technical-design.md | assets/technical-design.template.md | 完整开发 |
| docs/change-log.md | assets/change-log.template.md | 完整开发、bug 修复 |
| docs/code-review.md | assets/code-review.template.md | 完整开发、bug 修复 |
| docs/test-cases.md | assets/test-cases.template.md | 完整开发、运行验证、bug 修复 |
| docs/test-regression.md | assets/test-regression.template.md | 完整开发、bug 修复 |
| docs/bug-tracker.md | assets/bug-tracker.template.md | bug 修复 |
| docs/{scope}-report.md | assets/analysis-report.template.md | 纯分析 |
| docs/run-verification-report.md | assets/run-verification-report.template.md | 运行验证 |

中间产物（不一定交付给用户）：`docs/requirements.md`（markitdown 解析结果）、`docs/project-survey.md`（阶段 1c 项目勘察结论，由 `btf-explore-project` 写）。

## 内部子代理（仅主流程用 Task 调用，用户不直接触发）

定义在插件 `agents/` 下，随插件一起安装，无需额外配置：

- `agents/btf-explore-project.md` — 阶段 1c 子代理：隔离上下文里只读通读项目，写 `<项目根>/docs/project-survey.md` + 回摘要。
- `agents/btf-code-review.md` — 阶段 4 子代理：隔离上下文里只读审查本次改动，写 `<项目根>/docs/code-review.md` + 回分级问题摘要（只评不改，修复回主流程做）。
- `agents/btf-run-tests.md` — 阶段 6（6b+6c）子代理：隔离上下文里逐条跑用例 + 自愈 + 维护 bug-tracker，海量日志不回主线，只回传通过情况与 ⚠️ 需介入事项（不与用户交互；改代码自愈在子代理内做，需用户决策的回报主流程）。

三个子代理都接收**被分析项目根目录的绝对路径**作为 prompt 参数（用 Task 工具、`subagent_type` 指定对应代理名），产物统一落在该项目的 `docs/` 下，用户在自己项目里即可看到。它们各自的交互式前置（装工具、问目标端、连 MCP、卡点）都留在主流程，子代理只做不需要用户介入的纯执行部分。子代理由主 skill 显式用 Task 调用、不会被自动触发；环境不支持子代理时，对应阶段退化为主上下文内联执行。

## 参考文件

- `references/guardrails.md` — 红灯黑名单（14 条）+ 失败兜底速查表，每阶段动手前必看。
- `references/figma.md` — 用 Figma MCP 读取设计稿的方法与提取清单（MCP 由插件 `.mcp.json` 声明）。
- `references/web-testing.md` — Chrome MCP 测试 Web 前端的做法。
- `references/miniprogram-testing.md` — 小程序 MCP 测试的做法（MCP 由插件 `.mcp.json` 声明）。
- `scripts/ensure_markitdown.sh` — markitdown 检测/安装/验证。
- `scripts/btf-init.sh` — btf-init 命令的环境检测脚本。
- 插件根 `.mcp.json` — 声明 `figma`（Framelink）与 `weapp-dev`（小程序）两个 MCP server，安装插件即注册，运行时按需要设环境变量 `FIGMA_API_KEY` / `WEAPP_WS_ENDPOINT` 即可。
- 插件 `commands/btf-init.md` — 斜杠命令 `/btf-init`，安装插件后自动注册（命令名加前缀是为了避开内置的 `/init`）。
