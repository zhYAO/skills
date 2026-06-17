#!/usr/bin/env bash
# Ensure markitdown is installed and working. Detect -> install -> verify.
# Exits non-zero with a clear message if it cannot be made to work.
set -uo pipefail

check() {
  if command -v markitdown >/dev/null 2>&1 && markitdown --version >/dev/null 2>&1; then
    echo "OK: $(markitdown --version 2>&1 | head -n1)"
    return 0
  fi
  if python -m markitdown --version >/dev/null 2>&1; then
    echo "OK (python -m markitdown): $(python -m markitdown --version 2>&1 | head -n1)"
    return 0
  fi
  return 1
}

if check; then
  exit 0
fi

echo "markitdown not found. Installing..." >&2

# Prefer pipx (isolated), fall back to pip.
if command -v pipx >/dev/null 2>&1; then
  pipx install markitdown >/dev/null 2>&1 || pipx install 'markitdown[all]' >/dev/null 2>&1
fi

if ! check; then
  echo "Trying pip..." >&2
  pip install 'markitdown[all]' --break-system-packages >/dev/null 2>&1 \
    || pip install markitdown --break-system-packages >/dev/null 2>&1 \
    || python -m pip install 'markitdown[all]' --break-system-packages >/dev/null 2>&1
fi

if check; then
  exit 0
fi

echo "ERROR: markitdown install failed and verification did not pass." >&2
echo "Manual fix: 'pipx install markitdown' or 'pip install markitdown[all] --break-system-packages'." >&2
exit 1
