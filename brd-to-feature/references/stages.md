# 阶段 1-5, 7 详细工作流

> 完整开发任务主流程的阶段 1-5, 7 详细操作。**阶段 6 单独见 `build-and-test.md`**（阶段 6 占 79 行，单文件更易按需加载）。

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
- 若未连接 Figma MCP，**默认直接装 Framelink MCP**（`npx -y figma-developer-mcp --stdio` + Figma access token，安装与 token 获取见 `references/figma.md`），不必让用户在多个方案间选择；用户若明确说没有设计稿，可跳过、仅按需求文档开发。不要假装能看到设计稿。

读取到设计稿后，把关键信息沉淀进技术文档（阶段 2）：涉及的页面/组件清单、布局结构、间距与栅格、配色与字体 token、关键交互状态（hover/active/disabled/空态/加载/错误）、以及与现有项目组件的对应关系。开发时（阶段 3）严格对照这些还原，而不是凭印象画 UI。

详见 `references/figma.md`。

### 1c. 阅读整个项目（委派给 fork 子 skill）

解析完输入后，通读项目、建立全局认知再动手。**这一步委派给内部子 skill `btf-explore-project` 执行**——它在隔离的 fork 上下文里只读地通读项目，把几十个文件的原文挡在主上下文之外，只回传摘要，从而避免污染主流程上下文。

调用方式：用 Skill 工具调用 `btf-explore-project`，**参数传被分析项目根目录的绝对路径**（子任务在 fork 上下文里没有主对话的工作目录，必须靠这个绝对路径定位）。它会：

- 在 fork 上下文里读清技术栈/框架（含是否 Taro / uni-app 跨端框架）、目录结构、组件库与设计 token、代码风格与约定、现有测试方式；
- 把完整结论写到 **`<项目根>/docs/project-survey.md`**（写在项目自己的 `docs/` 下，用户能直接看到）；
- 回传一段摘要（框架与目标端、可复用组件/token、必须遵守的约定、测试方式、风险点），末尾附写盘绝对路径。

子任务返回后，主流程**读取 `<项目根>/docs/project-survey.md`** 作为阶段 2 写技术文档的依据。目的始终是让后续改动**贴合现有约定**、做外科手术式小改动，而不是引入与项目格格不入的新模式。

> 注：`btf-explore-project` 是本 skill 的内部子 skill（`user-invocable: false`），只由本主流程调用，用户不直接触发。若运行环境不支持 `context: fork`，退化为在主上下文里按上面 6 点自行通读项目即可。

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

### 4a. 审查（委派给 fork 子 skill）

审查动作**委派给内部子 skill `btf-code-review` 执行**——它在隔离的 fork 上下文里，用一双不被开发过程带偏的眼睛重新读 diff，既获得「第二双眼睛」的客观性，又把大量 diff 内容挡在主上下文之外。

调用方式：用 Skill 工具调用 `btf-code-review`，**参数传被审查项目根目录的绝对路径**与 `docs/technical-design.md` 路径（供它对照需求一致性；fork 上下文需绝对路径定位）。它会：

- `git status` + `git diff HEAD` 拿到本次改动（含新增文件），逐文件按六维度（需求与设计一致性 / 正确性与边界 / 安全 / 项目约定一致性 / 可维护性 / 性能）严格核对；
- 把结论按 `assets/code-review.template.md` 写到 **`<项目根>/docs/code-review.md`**（写在项目自己的 `docs/` 下，用户能直接看到）；
- 回传分级问题摘要——**先列阻塞级**（文件:行、问题、建议改法），再列建议级，最后给「是否存在阻塞项」的总体结论，附写盘绝对路径。

> 注：`btf-code-review` 是本 skill 的内部子 skill（`user-invocable: false`），只由本主流程调用，用户不直接触发。它**只评不改**。若运行环境不支持 `context: fork`，退化为在主上下文里自己按上述六维度逐文件核对。

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

## 变体任务（非完整开发）的精简路径

下面三类任务**不走完整七阶段**，按各自的精简路径走，只产出对应文档（硬套七阶段 = 红名单 #12）：

- **纯分析任务**（性能分析 / 代码审计 / 安全扫描）：① 阶段 1（解析输入 + 阶段 1c 通读项目，委派 `btf-explore-project`）→ ② 按分析主题逐项排查并取证（性能要实测、审计要逐文件）→ ③ 用 `assets/analysis-report.template.md` 产出**一份主报告** `docs/{scope}-report.md`（如 `performance-report.md`）。无开发、无卡点、无测试。

- **运行验证任务**（跑回归 / 设计稿截图比对）：① 阶段 1c 通读项目（如需）→ ② 阶段 5 写/复用测试用例 → ③ 阶段 6 执行测试 + 自愈 → ④ 用 `assets/run-verification-report.template.md` 产出 `docs/run-verification-report.md`。无技术文档、无卡点 1（直接进测试）。

- **bug 修复任务**：① **先复现**（阶段 5 写 TC-bug-XXX 复现用例）→ ② 登记 `docs/bug-tracker.md`（状态 `open`）→ ③ 定位修复（阶段 3 改动 + change-log）→ ④ 阶段 4 审查（委派 `btf-code-review`）→ ⑤ 阶段 6 回归 + bug 状态机推进 → ⑥ 阶段 7 回归文档（含 bug 修复章节）。产出 test-cases + bug-tracker + test-regression 三份。

完整开发任务才走上面完整的七阶段。
