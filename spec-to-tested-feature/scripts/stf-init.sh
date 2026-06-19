#!/usr/bin/env bash
# stf-init: detect the tools this skill depends on and report status.
# This script only DETECTS and reports. It does not install MCP servers or
# touch the agent's MCP config — installation/guidance is driven by SKILL.md
# (so the agent can ask the user before changing their environment).
#
# Usage: bash scripts/stf-init.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()   { echo "  [OK]    $1"; }
miss() { echo "  [MISS]  $1"; }
note() { echo "          $1"; }

echo "=== spec-to-tested-feature :: 环境检测 (stf-init) ==="
echo

# 1. markitdown (command-line installable; required)
echo "1) markitdown (需求文档解析，必需)"
if command -v markitdown >/dev/null 2>&1 && markitdown --version >/dev/null 2>&1; then
  ok "$(markitdown --version 2>&1 | head -n1)"
elif python -m markitdown --version >/dev/null 2>&1; then
  ok "python -m markitdown 可用"
else
  miss "未安装"
  note "可自动安装：bash scripts/ensure_markitdown.sh"
fi
echo

# 2. uv (needed to install the wechat miniprogram MCP)
echo "2) uv (安装小程序 MCP 用)"
if command -v uv >/dev/null 2>&1; then
  ok "$(uv --version 2>&1 | head -n1)"
  if uv tool list 2>/dev/null | grep -qi wechat-devtools-mcp; then
    ok "wechat-devtools-mcp 已通过 uv 安装"
  else
    miss "wechat-devtools-mcp 未安装（测微信小程序时需要）"
    note "可自动安装：uv tool install wechat-devtools-mcp --force"
    note "装完仍需：配 WECHAT_DEVTOOLS_CLI + WECHAT_PROJECT_PATH，并在开发者工具开启服务端口"
  fi
else
  miss "uv 未安装（测微信小程序时需要）"
  note "可自动安装：pip install uv"
fi
echo

# 3 & 4: MCP servers (Figma / Chrome) cannot be reliably detected from a shell —
# they live in the agent's MCP runtime. The agent checks its own tool list.
echo "3) Figma MCP (按设计稿开发用) — 由 agent 检查工具列表里是否有 figma 工具"
note "缺失指引见 references/figma.md（含 Framelink token 获取方式）"
echo
echo "4) Chrome MCP (测 Web 前端用) — 由 agent 检查工具列表里是否有 Chrome 工具"
note "只能人工连接浏览器扩展，见 references/web-testing.md"
echo

echo "=== 检测完成 ==="
echo "命令行类（markitdown / uv / 小程序 MCP）：征得用户同意后可自动安装。"
echo "MCP / token / 浏览器扩展：由 agent 按上述 references 给用户指引。"
