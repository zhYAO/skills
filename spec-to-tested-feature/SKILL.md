---
name: spec-to-tested-feature
description: 端到端的需求驱动开发工作流，跑在 Claude Code / Cursor / Trae 等 coding agent 上。当用户提供一份需求文档（pptx/md/txt/pdf/docx 等）和/或一份 Figma 设计稿，希望"按需求和设计稿把功能开发出来并测试通过"时使用本 skill。它把"解析需求 → 技术文档（人工卡点）→ 开发 → 代码审查 → 测试用例 → 自动化测试自愈 → 回归文档"固化成一条流水线，测试用 Chrome MCP（Web 前端）或小程序 MCP（微信小程序）。只要用户提到"按需求文档开发""照着设计稿做""完整开发流程""从需求到测试一条龙""parse requirements and build""implement from Figma"之类，即使没逐字点名本 skill，也应触发它。
---

# Spec-to-Tested-Feature 工作流

这是一个固定阶段、带一个人工卡点的端到端开发工作流。目标：把一份需求文档（和可选的 Figma 设计稿）变成已开发完成、且通过自动化测试的功能，并沿途产出 5 份文档。

为什么用固定流程：需求驱动开发最容易出问题的地方是"需求没对齐就开干"和"开发完没验证就交付"。本流程在需求理解后插入唯一一个人工卡点（技术文档确认），其余阶段尽量自动化，让人只在最关键处介入。

## 适用环境

- 运行在 Claude Code / Cursor / Trae 等支持 MCP 的 coding agent 中。
- 测试目标：Web 前端（用 Chrome MCP）或微信小程序（用小程序 MCP）。跨端框架（Taro / uni-app）按用户选定的目标端编译后再测。在阶段 6 自动判定项目类型后选择。
- 设计稿：通过 Figma MCP 读取（若提供了设计稿链接/文件 key）。

## 总览：七个阶段

1. **解析输入** — 需求文档 → md（markitdown）；设计稿 → 结构与样式（Figma MCP）；阅读整个项目。
2. **技术文档** — 产出 `docs/technical-design.md` → **【人工卡点】** 询问是否需要修改需求/方案，确认后才继续。
3. **开发** — 按需求 + 设计稿实现；完成后产出 `docs/change-log.md`（改动文件清单与说明）。
4. **严格代码 review** — 测试前对本次改动做严格代码审查，发现问题先修复，产出 `docs/code-review.md`。
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
- 若未连接 Figma MCP，**先问用户是否要现在自动安装/连接**（安装命令见 `references/figma.md`），不要不打招呼就改用户环境；用户也可选择跳过设计稿、仅按需求文档开发。不要假装能看到设计稿。

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

## 阶段 2：技术文档 +【人工卡点】

基于需求 md、设计稿、项目现状，产出技术设计文档。用 `assets/technical-design.template.md` 作为骨架，写到 `docs/technical-design.md`。

文档应覆盖：需求理解与范围、设计稿还原要点（页面/组件/交互状态）、技术方案与涉及模块、数据结构/接口、改动计划（要新增/修改哪些文件）、风险与未决问题、验收标准。

写完后，**这是整个流程唯一的人工卡点。停下来，明确询问用户：**

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

把审查结论写到 `docs/code-review.md`（用 `assets/code-review.template.md`）：审查范围、按维度的发现、问题分级、已修复项、遗留建议。只有阻塞级问题全部清零后，才进入测试阶段。

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

#### 6a-编译前置（跨端框架必做）

跨端框架的源码要先编译成目标端产物才能测，**不要假设打包命令**——不同 Taro/uni-app 项目脚本名各异，有的还套了自定义构建。先读 `package.json` 的 `scripts` 字段，找到真实的打包/启动命令：

```bash
cat package.json   # 看 scripts，找类似 build:weapp / dev:weapp / build:h5 / dev:h5 的项
```

- **测微信小程序**：跑项目里实际的小程序构建脚本（常见 `npm run build:weapp` 或 `dev:weapp`，但**以 scripts 里真实存在的为准**），产出编译目录（Taro 一般是 `dist/`，但也可能被项目改过——看构建输出或 `config/` 配置确认）。**小程序 MCP 的 `WECHAT_PROJECT_PATH` / 开发者工具打开的目录必须指向这个编译产物目录，不是 `src/` 源码根。** 找不到对应脚本时，停下来问用户该项目怎么编小程序。
- **测 H5**：跑项目里实际的 H5 启动脚本（常见 `npm run dev:h5`），拿到本地 URL，再走 Chrome MCP。

原生小程序 / 普通 Web 前端无需此步。

### 6b. 执行测试

先确认对应的测试 MCP 已连接，没连接就按 reference 里的「缺失检查 + 自动安装/连接」处理（先征得用户同意再装）。再确保应用可运行（普通 Web 起 dev server；跨端框架先完成 6a-编译前置；原生小程序用开发者工具/CLI 预览）。然后逐条执行阶段 5 的测试用例：

- **Web 前端**：用 Chrome MCP 导航到页面、操作元素、读取页面文本、并用 `read_console_messages` / `read_network_requests` 检查报错与接口。先确认 Chrome MCP 已连接。详见 `references/web-testing.md`。
- **微信小程序**：用小程序 MCP 操作模拟器、跳转页面、触发交互、断言渲染。详见 `references/miniprogram-testing.md`。

UI 还原类用例对照 Figma 设计稿核对关键视觉（布局/间距/配色/字号）。

### 6c. 自愈循环

发现问题时自动修复，而不是停下来等：

1. 定位问题（console 报错 / 接口失败 / 渲染或还原不符 / 逻辑错误）。
2. 修改代码修复。
3. 重跑相关用例确认通过。
4. 记录这一轮"问题 → 原因 → 修复 → 复测结果"，供回归文档使用。

**防回归**：单条修复后，如果改动面较大（动了共用逻辑、公共组件、全局状态等），不能只看修好的那条——要把之前已通过的相关用例也重跑一遍，确认没有"修好 A 弄坏 B"。所有用例最终全绿后，才进入阶段 7 出回归文档。

设定合理上限（如同一用例修复尝试 3 次仍不过），到上限仍无法自动解决时，停下来把现象、已尝试的修复、推测原因清晰报告给用户，请其决定，**不要无限循环或强行标记通过**。

修复涉及改代码时，同步更新 `docs/change-log.md`。

---

## 阶段 7：测试回归文档

测试全部通过（或明确记录了无法自动解决的项）后，产出回归文档 `docs/test-regression.md`（用 `assets/test-regression.template.md`）：

- 测试范围与环境（项目类型、所用 MCP、被测版本/commit）。
- 每条用例的执行结果（通过/失败/阻塞）。
- 自愈循环记录：发现的问题、根因、修复方式、复测结果。
- 设计稿还原核对结论。
- 遗留问题与建议。

产出后向用户汇报整体结果，结束流程。用 `present_files`（如可用）把 5 份文档（technical-design / change-log / code-review / test-cases / test-regression）提供给用户。

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
