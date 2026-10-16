#!/usr/bin/env bash
# Publish wiki/*.md to the GitHub Wiki remote.
# Prerequisite: create the first wiki page once in the GitHub UI
#   (open https://github.com/AssassiCirera/docs/wiki while logged in → Create the first page),
#   then re-run this script.
set -euo pipefail
unset GITHUB_TOKEN
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$(mktemp -d)"
cleanup() { rm -rf "$DEST"; }
trap cleanup EXIT

echo "Cloning wiki remote…"
if ! git clone "https://github.com/AssassiCirera/docs.wiki.git" "$DEST"; then
  echo "ERROR: wiki git remote not found yet."
  echo "Open https://github.com/AssassiCirera/docs/wiki while logged in as an org admin,"
  echo "click 'Create the first page', save any Home page, then re-run this script."
  exit 1
fi

cp "$ROOT/wiki/"*.md "$DEST/"
cd "$DEST"
git add *.md
if git diff --cached --quiet; then
  echo "No wiki content changes to push."
  exit 0
fi
git -c user.email="arnaugarcia@users.noreply.github.com" -c user.name="arnaugarcia" \
  commit -m "Publish AssassíCirera documentation wiki"
git push origin HEAD
echo "Published: https://github.com/AssassiCirera/docs/wiki"
