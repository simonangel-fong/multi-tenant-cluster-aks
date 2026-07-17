#!/usr/bin/env bash
# PostToolUse hook: runs after Edit/Write tool calls.
# Reads the hook JSON payload from stdin, inspects tool_input.file_path,
# and runs the appropriate validator based on file location/extension.
#
# - infra/**/*.tf            -> terraform fmt + terraform validate
# - argocd/** or tenants/**  -> JSON/YAML syntax check (kubeconform if present)
#
# Non-zero exit + stderr message blocks/warns in Claude Code; keep this
# fast and non-destructive (fmt rewrites in place, which is expected).

set -euo pipefail

payload="$(cat)"
file_path="$(python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("file_path", ""))
except Exception:
    print("")
' <<<"$payload")"

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

repo_root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || echo "")"

case "$file_path" in
  */infra/*.tf)
    if command -v terraform >/dev/null 2>&1; then
      dir="$(dirname "$file_path")"
      echo "[hook] terraform fmt: $file_path" >&2
      terraform fmt "$file_path" >&2 || true
      echo "[hook] terraform validate: $dir" >&2
      ( cd "$dir/.." 2>/dev/null && terraform validate >&2 ) || \
        echo "[hook] terraform validate skipped (module not init'd or invalid dir)" >&2
    else
      echo "[hook] terraform not found on PATH; skipping fmt/validate" >&2
    fi
    ;;
  */argocd/*.yaml|*/argocd/*.yml|*/demo-app/*.yaml|*/demo-app/*.yml)
    if command -v kubeconform >/dev/null 2>&1; then
      echo "[hook] kubeconform: $file_path" >&2
      kubeconform -summary "$file_path" >&2 || echo "[hook] kubeconform reported issues in $file_path" >&2
    else
      python3 -c "import yaml,sys; yaml.safe_load_all(open(sys.argv[1]))" "$file_path" 2>&2 \
        && echo "[hook] YAML syntax OK: $file_path" >&2 \
        || echo "[hook] YAML syntax ERROR: $file_path" >&2
    fi
    ;;
  */tenants/*.json)
    python3 -c '
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
required = {"name", "sourceRepo", "manifestPath"}
missing = required - data.keys()
extra = data.keys() - required
if missing:
    print(f"[hook] tenant JSON missing keys {missing}: {path}", file=sys.stderr)
    sys.exit(1)
if extra:
    print(f"[hook] tenant JSON has unexpected keys {extra}: {path}", file=sys.stderr)
name = data.get("name", "")
import re
if not re.fullmatch(r"[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?", name):
    print(f"[hook] tenant name not DNS-label-safe: {name!r} in {path}", file=sys.stderr)
    sys.exit(1)
print(f"[hook] tenant JSON OK: {path}", file=sys.stderr)
' "$file_path"
    ;;
  *)
    exit 0
    ;;
esac
