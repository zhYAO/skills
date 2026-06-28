#!/usr/bin/env bash
# btf-init: detect the tools this skill depends on and report status.
# This script only DETECTS and reports. It does not install MCP servers or
# touch the agent's MCP config — installation/guidance is driven by SKILL.md
# (so the agent can ask the user before changing their environment).
#
# Usage: bash scripts/btf-init.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()   { echo "  [OK]    $1"; }
miss() { echo "  [MISS]  $1"; }
note() { echo "          $1"; }

echo "=== brd-to-feature :: 环境检测 (btf-init) ==="
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

# 2. Node.js (needed to run the wechat miniprogram MCP: @yfme/weapp-dev-mcp via npx)
echo "2) Node.js / npx (运行小程序 MCP @yfme/weapp-dev-mcp 用)"
if command -v node >/dev/null 2>&1; then
  NODE_VER="$(node --version 2>&1)"
  NODE_MAJOR="$(echo "$NODE_VER" | sed 's/^v\([0-9]*\).*/\1/')"
  if [ "${NODE_MAJOR:-0}" -ge 18 ] 2>/dev/null; then
    ok "Node.js $NODE_VER (满足 18+)"
  else
    miss "Node.js $NODE_VER 版本过低（weapp-dev-mcp 需要 18+）"
  fi
  command -v npx >/dev/null 2>&1 && ok "npx 可用（weapp-dev-mcp 用 npx 直接运行，无需预装）" \
    || miss "npx 不可用"
else
  miss "Node.js 未安装（测微信小程序时需要，需 18+）"
  note "请安装 Node.js 18+（https://nodejs.org）"
fi
note "小程序 MCP 走 npx -y @yfme/weapp-dev-mcp，无需全局安装，配进 agent MCP 即可。"
echo

# 2.5 微信开发者工具 + 9420 端口（小程序测试前置）
echo "2.5) 微信开发者工具 + 9420 自动化端口 (测微信小程序时)"
# 检测常见安装路径
IDE_BAT=""
for p in \
  "C:/Program Files (x86)/Tencent/微信web开发者工具/cli.bat" \
  "/Applications/wechatwebdevtools.app/Contents/MacOS/cli"; do
  if [ -e "$p" ]; then IDE_BAT="$p"; break; fi
done
if [ -n "$IDE_BAT" ]; then ok "微信开发者工具 cli: $IDE_BAT"; else
  miss "未找到微信开发者工具 cli"
  note "Windows 默认: C:\\Program Files (x86)\\Tencent\\微信web开发者工具\\cli.bat"
  note "macOS 默认: /Applications/wechatwebdevtools.app/Contents/MacOS/cli"
  note "agent 应主动询问用户安装路径/手动启动方式，不要擅自猜测默认路径（见 SKILL.md 阶段 6b-前置 + 红名单 #13）"
fi
# 9420 端口（Windows 用 netstat，macOS 用 lsof）
if command -v netstat >/dev/null 2>&1; then
  if netstat -an 2>/dev/null | grep -q ':9420.*LISTEN'; then ok "9420 端口监听中"
  else miss "9420 端口未监听（IDE 未启动或未开自动化端口）"; fi
elif command -v lsof >/dev/null 2>&1; then
  if lsof -i :9420 >/dev/null 2>&1; then ok "9420 端口监听中"
  else miss "9420 端口未监听"; fi
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
