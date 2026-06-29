# _template — 新增 skill 的脚手架

新增一个 skill 时，**复制本目录**改名即可，避免每次从零搭结构：

```bash
cp -R _template <skill-name>
```

然后：

1. 把 `<skill-name>` 占位符全局替换成真实 skill 名（目录名 = SKILL.md 的 `name`，kebab-case）。
2. 填 `SKILL.md` 的 frontmatter（触发器）和正文（阶段表 / 卡点 / 文件地图）。
3. 用不到的目录（`scripts/` `references/` `assets/` `commands/` `skills/`）直接删，保持 skill 自包含、不留空壳。
4. 填或删 `INSTALL.md`（跨 agent 安装指引）。
5. **回到顶层 `README.md`，在「单元列表」表格补一行**（见仓库 `CLAUDE.md`）。

字段语义、命名约定、设计原则见仓库根的 `CLAUDE.md`。

> 注意：`_template/` 自身以 `_` 前缀命名，不是一个可加载的 skill——它只是拷贝源，agent 不应加载它。
