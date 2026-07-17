#!/usr/bin/env bash
# Merge LiteLLM upstream model prices with local custom entries.
# Upstream always wins on key conflicts; custom entries only fill gaps.
set -euo pipefail

UPSTREAM_URL="https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CUSTOM_FILE="$REPO_ROOT/custom_prices.json"
OUT_FILE="$REPO_ROOT/model_prices.json"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --retry 3 --connect-timeout 15 "$UPSTREAM_URL" -o "$TMP_DIR/upstream.json"

# Report custom keys that upstream now defines (upstream wins for those).
jq -r --slurpfile custom "$CUSTOM_FILE" \
  'keys[] as $k | select($custom[0] | has($k)) | "upstream-wins: \($k)"' \
  "$TMP_DIR/upstream.json"

# Merge: start from upstream, add only custom keys missing upstream.
jq -S --slurpfile custom "$CUSTOM_FILE" \
  '. as $up | ($custom[0] | with_entries(select(.key as $k | ($up | has($k)) | not))) as $missing | $up + $missing' \
  "$TMP_DIR/upstream.json" > "$TMP_DIR/model_prices.json"

mv "$TMP_DIR/model_prices.json" "$OUT_FILE"
echo "wrote $OUT_FILE ($(jq 'length' "$OUT_FILE") models)"
