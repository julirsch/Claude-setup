#!/usr/bin/env bash
# Setup for Claude Code cloud sessions (claude.ai/code). Cloud containers start fresh, so
# ~/.claude has to be rebuilt each time. Put this in the environment's Setup script:
#
#   git clone -q --depth 1 https://github.com/julirsch/claude-setup ~/.claude-setup || git -C ~/.claude-setup pull -q
#   bash ~/.claude-setup/cloud-setup.sh
#
# It installs the user-level kit (settings, hooks, skill-index, default skills) and Python
# code intelligence. Failures in optional steps are reported but don't stop the session.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$ROOT/install.sh" || { echo "cloud-setup: install.sh failed"; exit 1; }

# Python code intelligence (pyright LSP plugin). Skip with CLOUD_SETUP_NO_LSP=1.
if [[ -z ${CLOUD_SETUP_NO_LSP:-} ]] && command -v npm >/dev/null && command -v claude >/dev/null; then
  command -v pyright-langserver >/dev/null || npm install -g --silent pyright >/dev/null 2>&1 || echo "cloud-setup: pyright install failed (skipping LSP)"
  if command -v pyright-langserver >/dev/null; then
    [[ $(claude plugin marketplace list 2>/dev/null) == *claude-plugins-official* ]] \
      || claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1
    [[ $(claude plugin list 2>/dev/null) == *pyright-lsp* ]] \
      || claude plugin install pyright-lsp@claude-plugins-official >/dev/null 2>&1 \
      || echo "cloud-setup: pyright-lsp plugin install failed (skipping LSP)"
  fi
fi
echo "cloud-setup: done"
exit 0
