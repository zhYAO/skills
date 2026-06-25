---
name: spec-to-tested-feature
description: 端到端的需求驱动开发工作流，跑在 Claude Code / Cursor / Trae 等 coding agent 上。当用户提供一份需求文档（pptx/md/txt/pdf/docx 等）和/或一份 Figma 设计稿，希望"按需求和设计稿把功能开发出来并测试通过"时使用本 skill。它把"解析需求 → 技术文档（人工卡点）→ 开发 → 代码审查 → 测试用例 → 自动化测试自愈 → 回归文档"固化成一条流水线，测试用 Chrome MCP（Web 前端）或小程序 MCP（微信小程序）。只要用户提到"按需求文档开发""照着设计稿做""完整开发流程""从需求到测试一条龙""parse requirements and build""implement from Figma"之类，即使没逐字点名本 skill，也应触发它。
---

# Spec-to-Tested-Feature 工作流

这是一个固定阶段、带两个人工卡点的端到端开发工作流。目标：把一份需求文档（和可选的 Figma 设计稿）变成已开发完成、且通过自动化测试的功能，并沿途产出 5 份文档。

为什么用固定流程：需求驱动开发最容易出问题的地方是"需求没对齐就开干"和"开发完没验证就交付"。本流程设两个人工卡点——**卡点 1**在需求理解后（技术文档确认），**卡点 2**在开发+代码审查后、测试前（确认是否改代码、是否做设计稿截图比对），其余阶段尽量自动化，让人只在最关键处介入。

## 适用环境

- 运行在 Claude Code / Cursor / Trae 等支持 MCP 的 coding agent 中。
- 测试目标：Web 前端（用 Chrome MCP）或微信小程序（用小程序 MCP）。跨端框架（Taro / uni-app）按用户选定的目标端编译后再测。在阶段 6 自动判定项目类型后选择。
- 设计稿：通过 Figma MCP 读取（若提供了设计稿链接/文件 key）。

---

## stf-init 命令：初始化所需工具

当用户说 **`stf-init`** / **初始化环境** / **装一下这个 skill 需要的工具** 时，**只做环境准备，不解析任何需求、不开发**。目标：把本 skill 依赖的工具一次性检测、安装或给出获取指引（含 token 怎么拿），让后续正式流程能顺畅跑。

（命令名用 `stf-init` 而非 `init`，避免和 Claude Code 内置的 `/init` 命令冲突。）

运行方式：执行 `bash scripts/stf-init.sh` 做一轮自动检测，它会打印每个工具的状态（OK / 缺失）。然后按下面的清单逐项处理。**原则：能命令行自动装的，先征得用户同意再装；只能人工做的（浏览器扩展、token），给清晰步骤和获取链接，不要假装能代办。**

逐项处理：

1. **markitdown（必需）** — 跑 `bash scripts/ensure_markitdown.sh`，它自动检测→安装→验证。失败则把报错和手动命令给用户。
2. **小程序 MCP（测微信小程序需要）** — 检测有没有 `mp_*` / `page_*` / `element_*` 工具。没有就**问用户是否现在装**，同意后按 `references/miniprogram-testing.md` 的「缺失检查 + 自动安装」执行（用 `@yfme/weapp-dev-mcp`：配 MCP（`npx -y @yfme/weapp-dev-mcp` + `WEAPP_WS_ENDPOINT`）+ 命令行启动开发者工具并开启自动化端口）。
3. **Figma MCP（按设计稿开发需要）** — 检测有没有 `figma` 工具。没有就**默认直接装 Framelink**（不必让用户在方案间二选一，见 `references/figma.md`）：`npx -y figma-developer-mcp --stdio` + **Figma access token**。明确告诉用户 token 获取路径：Figma → `Settings` → `Security` → `Personal access tokens` → 生成，权限至少给 File content 读取；拿到后填进 MCP 配置的 `FIGMA_API_KEY`，别提交进仓库或打日志。（仅当用户明确偏好官方 Dev Mode 时才改用它。）
4. **Chrome MCP（测 Web 前端需要）** — 检测有没有 `mcp__*Chrome*` 之类工具。这个**只能人工**：引导用户装浏览器扩展并授权连接（见 `references/web-testing.md`）。

处理完后，给用户一份小结：哪些已就绪、哪些待用户操作（附下一步动作）、哪些本次用不到可跳过。**init 到此结束，不要顺势开始解析需求或开发**——正式流程由用户后续单独发起。

按需选择：如果用户明确只做某一类项目（比如只测小程序），其余 MCP 可以标注"本项目用不到"，不必强求装齐。

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

---

## 总览：七个阶段

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

**先检测，缺了再装，装完验证：**

```bash
# 检测
markitdown --version 2>/dev/null || python -m markitdown --version 2>/dev/null
```

若不存在，自动安装并复检（脚本已封装这套逻辑）：

```bash
bash scripts/ensure_markitdown.sh
```

该脚本会优先尝试 `pipx install markitdown`，失败则回退 `pip install 'markitdown[all]' --break-system-packages`，安装后再次 `--version` 验证，验证不通过会非零退出并打印原因。**安装失败不要静默继续**——告诉用户失败原因并停下来，因为后续步骤依赖解析结果。

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

### 1c. 阅读整个项目

解析完输入后，通读项目，建立全局认知后再动手：

- 技术栈与框架（看 `package.json` / `project.config.json`（小程序）/ 构建配置 / lockfile）。
- 目录结构、模块边界、现有组件库与设计规范。
- 代码风格、命名约定、状态管理、路由、API 层。
- 现有测试方式与脚本（`scripts.test`、是否有 e2e 等）。

目的是让后续改动**贴合现有约定**，做外科手术式的小改动，而不是引入与项目格格不入的新模式。

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

审查对象是本次改动（不是全项目）。先拿到改动清单与内容：

```bash
git status            # 全部受影响文件，含新增（Untracked）文件
git diff HEAD         # 已跟踪文件的具体改动；新文件直接读文件本身
```

逐文件、逐处改动严格核对（别漏看新增文件），至少覆盖以下维度：

- **需求与设计一致性**：是否完整实现了已确认技术文档里的范围与验收标准？UI 是否对照设计稿还原？有没有偷偷超出范围（scope creep）？
- **正确性与边界**：空值/异常输入/边界值/并发/竞态/错误处理是否考虑周全？有没有可能的 null/undefined、越界、未 await 的异步。
- **安全**：输入校验、注入、XSS、鉴权与越权、敏感信息（密钥/token）是否硬编码或泄漏到日志。
- **项目约定一致性**：命名、目录、代码风格、状态管理、复用既有组件与 token，是否与项目既有约定一致；有没有重复造轮子。
- **可维护性**：是否最小必要改动、有无顺手重构无关代码、有无死代码/调试残留（console.log、TODO、注释掉的代码）。
- **性能**：明显的低效循环、重复请求、大列表无虚拟化、不必要的重渲染等。

审查方式：可自己逐项核对；环境支持子代理时，也可派一个独立子代理做评审以获得"第二双眼睛"（更客观）。

**发现问题分级处理：**
- 阻塞级（bug、安全问题、需求未实现、严重不符约定）→ **当场修复**，修复后重新审查相关部分，并把改动同步进 `docs/change-log.md`。
- 建议级（可优化但不阻塞）→ 记录在评审文档里，由用户决定是否处理。

把审查结论写到 `docs/code-review.md`（用 `assets/code-review.template.md`）：审查范围、按维度的发现、问题分级、已修复项、遗留建议。只有阻塞级问题全部清零后，才到下面的测试前卡点。

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

### 6b-前置：IDE 启动 + MCP 就绪自检（跨端框架/原生小程序共用）

进入测试前必须确认小程序 MCP 已稳定连接，按下列步骤自检；任一步失败 → 🔴 STOP（见红名单 #11）。

1. **确认编译产物路径**（已在 §6a-编译前置确定：用户提供的 / agent 编译的，**不要重新猜测**）。

2. **探测微信开发者工具 cli 路径**（**找不到就问，不要猜**）：
   - 默认探测位置（`scripts/stf-init.sh` 的 2.5 段已做）：
     - Windows：`C:\Program Files (x86)\Tencent\微信web开发者工具\cli.bat`
     - macOS：`/Applications/wechatwebdevtools.app/Contents/MacOS/cli`
   - **探测不到时** → 询问用户：
     > 我没在你的机器上找到微信开发者工具的 cli（默认 Windows 路径 `C:\Program Files (x86)\Tencent\微信web开发者工具\cli.bat` 不存在）。请告诉我以下任一选项：
     > 1. 你的开发者工具装在哪个绝对路径？（可在 Windows「设置 → 应用」搜索"微信开发者工具"查看安装路径）
     > 2. 或者你自己手动启动 IDE + 开启自动化端口（IDE 内：设置 → 安全设置 → 服务端口 → 开启「HTTP 调试」和「自动化测试」），然后告诉我"已经手动开好了"
     > 3. 或者你希望我**降级到纯静态分析**（产物顶部标"运行通道 ⚠️ 仅静态分析"，见红名单 #11）
   - **禁止猜测**：不擅自改默认路径、不假设 WSL/Linux 环境、不假设符号链接或软链、不假设 IDE 已通过别的方式启动。

3. **启动开发者工具**（cli 路径已知后）：
   ```bash
   # Windows（路径换成探测到的真实路径）
   "<cli.bat 绝对路径>" auto \
     --project <§6a 确定的产物目录> --auto-port 9420
   ```
4. **sleep ≥ 45 秒**（首次启动；复用连接 ≥ 5 秒）。`references/miniprogram-testing.md` 明示首次就绪约需 45 秒。**不要 sleep 十几秒就重连**——会过早失败。
5. **三项探测**（必须全部通过才能进 6b）：
   - `Get-NetTCPConnection -LocalPort 9420` 状态 = `Listen`
   - `Get-Process wechatdevtools` 主窗口标题包含目标项目名
   - `mcp__weapp-dev__*` 工具列表 ≥ 1 个可用
6. **连接探测**：先调 `mp_listProjects`（不是 `mp_ensureConnection`）→ 再 `mp_ensureConnection`。
7. **重试退避表**（连接失败时）：

   | 重试次数 | sleep | 必换参数 |
   |---------|-------|----------|
   | 1 | 5s | `reconnect=true` |
   | 2 | 15s | `projectSelection` |
   | 3 | 30s | `reconnect=true + projectSelection` |
   | 4 | 60s | **🔴 STOP 上报用户** |

8. **STOP 信号**：工具消失 / 4 次重试全败 / IDE 主窗口标题不含项目名 → 报告用户，由用户决定走"等待 MCP 恢复"还是"标注降级后继续"。

### 6b. 执行测试

先确认对应的测试 MCP 已连接，没连接就按 reference 里的「缺失检查 + 自动安装/连接」处理（先征得用户同意再装）。再确保应用可运行（普通 Web 起 dev server；跨端框架先完成 6a-编译前置；原生小程序用开发者工具/CLI 预览）。然后逐条执行阶段 5 的测试用例：

- **Web 前端**：用 Chrome MCP 导航到页面、操作元素、读取页面文本、并用 `read_console_messages` / `read_network_requests` 检查报错与接口。先确认 Chrome MCP 已连接。详见 `references/web-testing.md`。
- **微信小程序**：用小程序 MCP（`weapp-dev-mcp`）连接开发者工具——`mp_ensureConnection` 验证连接、`mp_navigate` 跳转、`element_tap`/`element_input` 操作、`page_getData`/`mp_getLogs` 断言与查报错。详见 `references/miniprogram-testing.md`。

UI 还原类用例对照 Figma 设计稿核对关键视觉（布局/间距/配色/字号）。

### 6c. 自愈循环 + bug 状态跟踪

发现问题时自动修复，而不是停下来等。每次"发现 → 修复 → 验证"都要在 `docs/bug-tracker.md` 留下状态变更记录（与 `assets/bug-tracker.template.md` 对齐）。

#### 6c-1. 自愈循环主流程

1. **定位问题**（console 报错 / 接口失败 / 渲染或还原不符 / 逻辑错误）。
2. **登记 bug**：在 `docs/bug-tracker.md` 新增一行，状态 `open`，严重分级（🔴 阻塞 / 🟠 重要 / 🟡 一般 / 🟢 提示），记录现象、根因猜测、关联用例 ID（如 TC-XX）。
3. **修改代码修复**：状态变更为 `in_progress`。
4. **重跑该用例确认通过**：状态变更为 `fixed`，并把 commit hash 写到 bug-tracker.md 的「状态变更记录」。
5. **防回归重跑**：如果改动面较大（动了共用逻辑、公共组件、全局状态、跨端框架 runtime 等），把之前已通过的相关用例也重跑一遍——**只要有一条由绿变红，立即把那个 bug 重新 open**。

#### 6c-2. bug 状态机

```
        ┌──────────┐
        │  open    │ ← 发现 bug
        └────┬─────┘
             ↓
        ┌──────────┐
        │ in_progress │ ← 开始修复
        └────┬─────┘
             ↓
        ┌──────────┐
        │   fixed  │ ← 修复完成，等待验证
        └────┬─────┘
             ↓（回归通过 + 用户验收）
        ┌──────────┐
        │ verified │ ← 自动回归通过
        └────┬─────┘
             ↓
        ┌──────────┐
        │  closed  │ ← 上线 / 用户确认
        └──────────┘
             
（任何状态都可 → wontfix，需注明原因；fixed / verified 失败则回到 in_progress）
```

#### 6c-3. 上限与降级

- 同一 bug **修复尝试 3 次仍 fixed 不下来** → 状态回到 `in_progress`，把现象、已尝试修复、推测原因写到 bug-tracker.md，**STOP 上报用户**，由用户决定。
- 同一用例自愈失败上限同样是 3 次（与上方一致）。
- 修复涉及改代码时，同步更新 `docs/change-log.md`，并在 bug-tracker.md 该行补一条 commit 关联。

#### 6c-4. bug-tracker.md 何时写入

| 时机 | 写入内容 |
|------|----------|
| bug 发现 | 新增一行，状态 `open` |
| 开始改代码 | 状态变 `in_progress` |
| 修复完成 | 状态变 `fixed` + commit hash |
| 自动回归通过 | 状态变 `verified` |
| 用户验收 / 上线确认 | 状态变 `closed` |
| 用户明确说不修 | 状态变 `wontfix` + 原因 |
| 验证中发现新 bug | 新增一行（新 ID），原 bug 保持 `fixed` 不变 |

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
- **§6.1 防回归重跑记录**：列出阶段 6c-1 第 5 步要求的相关用例重跑结果。
- **§6.2 未关闭 bug**：如有未关闭（`open` / `in_progress` / `fixed` 未升 `verified`）的 bug，**禁止完成本次回归**——必须先回到阶段 6 处理。

**产出后向用户汇报整体结果，结束流程**。用 `present_files`（如可用）按任务类型提供文档：

| 任务类型 | 提供给用户的文档 |
|---------|-------------------|
| 完整开发任务 | technical-design + change-log + code-review + test-cases + test-regression |
| 纯分析任务 | 主报告（如 `performance-optimization.md`） |
| 运行验证任务 | test-cases + run-verification-report（或 test-regression） |
| bug 修复任务 | test-cases + bug-tracker + test-regression |

---

## 🚫 反例 / 红灯黑名单（绝对不要做）

以下每条都是真实会翻车的反模式。**每个阶段动手前对照本表一次，任一命中 → 停下来纠正，不要硬走。**

| # | 🚫 不要做 | 为什么 | 正确做法 |
|---|----------|--------|---------|
| 1 | 工具/扩展/token 假装能代办 | 浏览器扩展、Figma/小程序 token 只能人工，假装代办会让流程卡死且误导用户 | 给清晰步骤 + 获取链接，明确标注「需你操作」 |
| 2 | markitdown 解析失败后静默继续 | 后续全链路依赖解析结果，空内容往下走必然跑偏 | 报失败原因并停下；扫描件/图片 PDF 提示需 OCR 或文字版 |
| 3 | 没看到设计稿却假装看到、凭印象画 UI | Figma 未连接时臆造 UI，还原必然与设计稿不符 | 先连 Figma MCP；用户明说无设计稿才跳过 |
| 4 | 卡点 1 未确认就开发 / 卡点 2 未放行就测试 | 跳过人工卡点是本流程最大事故源（需求没对齐、改动没复核） | 🔴 STOP，拿到明确同意/放行再继续 |
| 5 | 为凑 diff 去 `git add` 暂存文件 | 污染暂存区，且改动清单失真 | 用 `git status` + `git diff HEAD`，新文件直接读文件 |
| 6 | 替用户假设要测哪个目标端 | 跨端框架可编多端，假设错则整轮测试白跑 | 识别到 Taro/uni-app 后明确问用户测小程序还是 H5 |
| 7 | 假设跨端框架的打包命令 | 各项目脚本名各异，命令猜错编不出产物 | 先读 `package.json` 的 `scripts`，找不到就问用户 |
| 8 | 小程序 MCP 指向 `src/` 源码根 | 跨端框架源码不能直接被开发者工具打开，必须用编译产物 | 指向编译产物目录（Taro 一般 `dist/`，以构建输出为准） |
| 9 | 自愈循环无限重试或强行标记通过 | 掩盖真实失败，交付不可信 | 同一用例修 3 次仍不过 → 停下报告用户决定 |
| 10 | stf-init 后顺势开始解析需求/开发 | init 只做环境准备，越界会打乱用户节奏 | init 给完小结即结束，正式流程由用户另行发起 |
| 11 | MCP/工具不可用时静默降级到静态/源码分析并继续产出报告（缺运行时实测数据） | 产出物看起来完整但实际缺关键数据，误导读者 | 🔴 STOP 报告用户决定走「等待 MCP 恢复」还是「标注降级后继续」，模板顶部必须填「运行通道」字段 |
| 12 | 任务类型与 skill 主流程不匹配时（如本次是纯分析任务），硬套 5 份文档 | 文档臃肿、模板不匹配、读者困惑 | 走变体路径（见 SKILL.md Step 0），按任务类型出文档 |
| 13 | 猜测编译产物路径 / 猜测 IDE 安装路径 | 不同项目配置差异巨大，猜错导致测试白跑或连不上 | 🔴 主动询问用户；用户未给之前禁止 `--project <自行假设的路径>` 与禁止假设默认 IDE 路径 |
| 14 | 用户未提供产物路径时擅自跑构建 / 用户未指定命令时擅自跑构建 | 用户可能有自定义构建流程，乱跑会破坏中间状态、覆盖产物 | 🔴 先问用户；用户授权后才能跑；跑哪个命令也必须用户明确（见 SKILL.md §6a-编译前置） |

---

## 🛟 失败兜底速查表（三段式 fallback）

各阶段的失败处理已写在对应阶段内，这里汇总成「触发条件 → 一线修复 → 仍失败兜底」三段式速查。**遇到下列情况按此表处理，绝不静默跳过、绝不空跑。**

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| markitdown 不存在/版本检测失败 | `bash scripts/ensure_markitdown.sh` 自动装并复检 | 报失败原因 + 手动命令给用户，**停下**（后续依赖解析结果） |
| 需求 PDF 解析结果为空/乱码 | 判断是否扫描件或图片型 PDF | 提示用户需 OCR 或提供文字版需求，不拿空内容往下走 |
| Figma MCP 未连接 | 默认装 Framelink（`npx -y figma-developer-mcp --stdio` + token，见 `references/figma.md`） | 用户明说无设计稿 → 仅按需求文档开发，不臆造 UI |
| 测试 MCP（Chrome/小程序）未连接 | 按对应 reference「缺失检查 + 自动安装」处理（先征得同意） | 装不上 → 把手动步骤给用户，暂停测试不强测 |
| 项目类型判不准 | 先看跨端框架依赖再看原生结构（见 6a） | 仍不确定 → 问用户以哪个目标端为准 |
| 跨端框架找不到打包脚本 | 读 `package.json` 的 `scripts` 找 `build:weapp`/`dev:h5` 等 | 找不到 → 停下问用户该项目怎么编目标端 |
| 同一测试用例自愈修 3 次仍不过 | 定位 → 改 → 复测循环（设上限） | 到上限 → 报现象/已试修复/推测原因给用户决定，不强标通过 |
| 不在 git 仓库（生成改动清单时） | 仍可 `git status`/`git diff HEAD` | 命令失败 → 改为直接读改动文件列清单，并告知用户清单可能不全 |
| 小程序 MCP 连接超时/断开/工具消失 | 调 `mp_listProjects` 探测 → 重连（backoff 5s/15s/30s/60s，必换 `projectSelection` 或 `reconnect`） | **🔴 STOP 上报用户**，由用户决定是等待 MCP 恢复、降级到静态分析（产物须标"运行通道 ❌ 仅静态分析"）、还是取消本次任务 |
| Chrome MCP 连接失败 | `mcp__Claude_in_Chrome__*` 工具列表核对 → 提示用户重连浏览器扩展 | 同上：🔴 STOP 并由用户决定 |
| 任务类型无法识别（无需求文档/无设计稿/无目标端） | 用 AskUserQuestion 确认本次任务类型（完整开发/纯分析/运行验证） | 不允许擅自假定，按 Step 0 三种变体路径走 |

---

## 文档产出物一览

| 阶段 | 文档 | 模板 |
|------|------|------|
| 2 | docs/technical-design.md | assets/technical-design.template.md |
| 3 | docs/change-log.md | assets/change-log.template.md |
| 4 | docs/code-review.md | assets/code-review.template.md |
| 5 | docs/test-cases.md | assets/test-cases.template.md |
| 7 | docs/test-regression.md | assets/test-regression.template.md |

中间产物：`docs/requirements.md`（markitdown 解析结果）。

## 参考文件

- `references/figma.md` — 用 Figma MCP 读取设计稿的方法与提取清单。
- `references/web-testing.md` — Chrome MCP 测试 Web 前端的做法。
- `references/miniprogram-testing.md` — 小程序 MCP 测试的做法。
- `scripts/ensure_markitdown.sh` — markitdown 检测/安装/验证。
- `scripts/stf-init.sh` — stf-init 命令的环境检测脚本。
- `commands/stf-init.md` — Claude Code 斜杠命令 `/stf-init`（把文件放到项目或全局的 `.claude/commands/` 下即可用 `/stf-init` 触发；其它 agent 直接说 "stf-init" 走 SKILL.md 的 stf-init 流程）。命令名加前缀是为了避开内置的 `/init`。
