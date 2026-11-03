#!/usr/bin/env bash
set -euo pipefail

# Official source. The mirror retains this repo's build automation controls.
UPSTREAM="https://github.com/thesnarkitecht/rembrandt.git"
STATUS=".github/sync/upstream-head.sha"
CONTROL=(
  .github/workflows/auto-sync-release.yml
  .github/workflows/build-mirror.yml
  .github/scripts/sync-upstream.sh
  .github/docs/AUTO_BUILD.md
)

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add official "$UPSTREAM" 2>/dev/null || git remote set-url official "$UPSTREAM"
git -c http.version=HTTP/1.1 fetch --no-tags --depth=1 official refs/heads/main
source_sha="$(git rev-parse FETCH_HEAD)"
prev_sha="$(cat "$STATUS" 2>/dev/null || true)"
echo "source_sha=$source_sha" >> "$GITHUB_OUTPUT"
if [[ "$source_sha" == "$prev_sha" ]]; then
  echo "changed=false" >> "$GITHUB_OUTPUT"
  echo "mirror_sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
  echo "Upstream unchanged at $source_sha; skipping build."
  exit 0
fi

overlay="$(mktemp -d)"
trap 'rm -rf "$overlay"' EXIT
for file in "${CONTROL[@]}"; do
  test -f "$file" || { echo "::error::Missing CI control: $file"; exit 1; }
  mkdir -p "$overlay/$(dirname "$file")"
  cp "$file" "$overlay/$file"
done

# Bring in the full upstream tree, then restore the local CI controls.
# This creates a normal descendant commit, never a forced rewrite.
git read-tree --reset -u FETCH_HEAD
for file in "${CONTROL[@]}"; do
  mkdir -p "$(dirname "$file")"
  cp "$overlay/$file" "$file"
done
mkdir -p "$(dirname "$STATUS")"
printf '%s\n' "$source_sha" > "$STATUS"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore(mirror): sync Rembrandt upstream (${source_sha:0:12})"
  git push origin HEAD:main
fi

echo "changed=true" >> "$GITHUB_OUTPUT"
echo "mirror_sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
echo "Mirrored $source_sha into $(git rev-parse HEAD)"
