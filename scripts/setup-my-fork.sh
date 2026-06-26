#!/usr/bin/env bash
# Thiết lập fork GitHub và push repo VieNeu-TTS của bạn.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GH="${GH:-gh}"
if ! command -v "$GH" >/dev/null 2>&1; then
  GH="/opt/homebrew/bin/gh"
fi

UPSTREAM="${UPSTREAM:-pnnbao97/VieNeu-TTS}"
FORK_OWNER="${FORK_OWNER:-CongND2K}"
FORK_REPO="${FORK_REPO:-VieNeu-TTS}"

echo "== VieNeu-TTS fork setup =="
echo "Upstream: https://github.com/$UPSTREAM"
echo "Your fork: https://github.com/$FORK_OWNER/$FORK_REPO"
echo ""

if ! "$GH" auth status >/dev/null 2>&1; then
  echo "Chua dang nhap GitHub. Dang mo trinh dang nhap..."
  "$GH" auth login -h github.com -p https -w
fi

echo ">> Tao fork (neu chua co)..."
if ! git ls-remote "https://github.com/$FORK_OWNER/$FORK_REPO.git" HEAD >/dev/null 2>&1; then
  "$GH" repo fork "$UPSTREAM" --clone=false --fork-name "$FORK_REPO"
  echo "Da tao fork: https://github.com/$FORK_OWNER/$FORK_REPO"
else
  echo "Fork da ton tai."
fi

echo ">> Cau hinh remote..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$FORK_OWNER/$FORK_REPO.git"
git remote remove upstream 2>/dev/null || true
git remote add upstream "https://github.com/$UPSTREAM.git"

echo ">> Dong bo upstream..."
git fetch upstream
git rebase upstream/main

echo ">> Push len fork cua ban..."
git push -u origin main

echo ""
echo "Xong! Repo cua ban: https://github.com/$FORK_OWNER/$FORK_REPO"
