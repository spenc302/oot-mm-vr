#!/usr/bin/env bash
# Fetch Ship of Harkinian at the commit pinned in UPSTREAM.json into src/shipwright,
# keep our soh/soh/VR directory, and apply patches/*.patch.
# Usage: tools/fetch-upstream.sh [--no-submodules]
set -euo pipefail
cd "$(dirname "$0")/.."

SUBMODULES=1
[ "${1:-}" = "--no-submodules" ] && SUBMODULES=0

URL=$(python3 -c 'import json;print(json.load(open("UPSTREAM.json"))["shipwright"]["url"])')
COMMIT=$(python3 -c 'import json;print(json.load(open("UPSTREAM.json"))["shipwright"]["commit"])')

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --no-checkout "$URL" "$TMP/sw"
git -C "$TMP/sw" checkout "$COMMIT"
if [ "$SUBMODULES" = 1 ]; then
    git -C "$TMP/sw" submodule update --init --recursive
fi
# Flatten: drop nested git metadata so this tree can sit inside our repo (as MM VR does).
find "$TMP/sw" -name .git -prune -exec rm -rf {} +

VR_KEEP="$TMP/VR"
if [ -d src/shipwright/soh/soh/VR ]; then
    cp -a src/shipwright/soh/soh/VR "$VR_KEEP"
fi
rm -rf src/shipwright
mv "$TMP/sw" src/shipwright
if [ -d "$VR_KEEP" ]; then
    mkdir -p src/shipwright/soh/soh
    rm -rf src/shipwright/soh/soh/VR
    cp -a "$VR_KEEP" src/shipwright/soh/soh/VR
fi

for p in patches/*.patch; do
    if git apply --directory=src/shipwright --check "$p" 2>/dev/null; then
        git apply --directory=src/shipwright "$p"
        echo "applied  $p"
    elif git apply --directory=src/shipwright --check -R "$p" 2>/dev/null; then
        echo "already  $p"
    else
        echo "FAILED   $p" >&2
        exit 1
    fi
done
echo "Upstream ready at src/shipwright (commit $COMMIT)."
