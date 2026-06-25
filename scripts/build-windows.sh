#!/usr/bin/env bash
# Build VieNeu-TTS portable package for Windows from macOS/Linux.
#
# Usage:
#   ./scripts/build-windows.sh              # trigger GitHub Actions (CI)
#   ./scripts/build-windows.sh --wait       # trigger CI, wait, download ZIP
#   ./scripts/build-windows.sh --local      # pack source ZIP for manual Windows build
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WORKFLOW="build-portable-windows.yml"
MODE="ci"
WAIT=false

usage() {
  cat <<'EOF'
Usage: ./scripts/build-windows.sh [OPTIONS]

Build VieNeu-TTS portable package for Windows.

Options:
  --ci       Trigger GitHub Actions build (default)
  --local    Create dist/vieneu-source-for-windows.zip for manual build on Windows
  --wait     With --ci: wait for workflow and download artifact to dist/
  -h, --help Show this help

Examples:
  ./scripts/build-windows.sh --wait
  ./scripts/build-windows.sh --local
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ci) MODE="ci" ;;
    --local) MODE="local" ;;
    --wait) WAIT=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

pack_source() {
  mkdir -p dist
  local zip_path="dist/vieneu-source-for-windows.zip"
  rm -f "$zip_path"

  echo ">> Packing source for Windows build..."
  zip -r "$zip_path" . \
    -x "*.git*" \
    -x "*/.venv/*" \
    -x "*/.xpu_venv/*" \
    -x "*/__pycache__/*" \
    -x "*__pycache__*" \
    -x "dist/*" \
    -x "dist/**" \
    -x "*/outputs/*" \
    -x "*/.pytest_cache/*" \
    -x "*/finetune/dataset/*" \
    -x "*/finetune/output/*" \
    -x "*/merged_models_cache/*" \
    -x "*/.DS_Store" \
    -x "*/.env"

  echo ""
  echo "Created: $zip_path"
  echo ""
  echo "Next steps on Windows:"
  echo "  1. Copy $zip_path to your Windows machine"
  echo "  2. Extract the ZIP"
  echo "  3. Run: powershell -ExecutionPolicy Bypass -File scripts\\build-portable.ps1"
  echo "  4. Output: dist\\VieNeu-TTS-Portable-win64.zip"
}

trigger_ci() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed." >&2
    echo "Install: brew install gh && gh auth login" >&2
    echo "Or use: ./scripts/build-windows.sh --local" >&2
    exit 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: gh is not authenticated. Run: gh auth login" >&2
    exit 1
  fi

  local workflow_file=".github/workflows/$WORKFLOW"
  if [[ ! -f "$workflow_file" ]]; then
    echo "Error: missing $workflow_file" >&2
    exit 1
  fi

  echo ">> Triggering GitHub Actions workflow: $WORKFLOW"
  gh workflow run "$WORKFLOW"
  sleep 3

  local run_id
  run_id="$(gh run list --workflow="$WORKFLOW" --limit 1 --json databaseId --jq '.[0].databaseId')"

  if [[ -z "$run_id" || "$run_id" == "null" ]]; then
    echo "Error: could not find workflow run." >&2
    exit 1
  fi

  echo ">> Workflow run: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$run_id"

  if [[ "$WAIT" != true ]]; then
    echo ""
    echo "Build started. To wait and download artifact:"
    echo "  gh run watch $run_id"
    echo "  gh run download $run_id -D dist/"
    exit 0
  fi

  echo ">> Waiting for workflow to complete (may take 20-60 minutes)..."
  gh run watch "$run_id" --exit-status

  mkdir -p dist
  echo ">> Downloading artifact..."
  gh run download "$run_id" -D dist/

  echo ""
  echo "Done. Artifact downloaded to dist/"
  ls -lh dist/ 2>/dev/null || true
}

case "$MODE" in
  local) pack_source ;;
  ci) trigger_ci ;;
esac
