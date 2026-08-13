#!/usr/bin/env zsh

set -euo pipefail

repo_dir="${0:A:h:h}"
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

# The launcher only checks that Pi is installed during --dry-run.
print '#!/bin/sh' > "$tmp_dir/pi"
print 'exit 0' >> "$tmp_dir/pi"
chmod +x "$tmp_dir/pi"
export PATH="$tmp_dir:$PATH"

codex_id='019fa000-1111-7222-8333-444455556666'
codex_output=$(CODEX_THREAD_ID="$codex_id" \
  "$repo_dir/scripts/pi-codex-channel" glm52 test --prompt x --dry-run)
[[ "$codex_output" == *'session_id=cdx-019fa000-1111-glm52'* ]]

project_output=$(cd "$repo_dir" && env -u CODEX_THREAD_ID \
  "$repo_dir/scripts/pi-codex-channel" glm52 test --prompt x --dry-run)
[[ "$project_output" == *'session_id=cdx-cc-'*'-glm52'* ]]

print 'glm52 = example/model' > "$tmp_dir/channels.conf"
override_output=$(CODEX_THREAD_ID="$codex_id" \
  PI_CODEX_CHANNELS_CONF="$tmp_dir/channels.conf" \
  "$repo_dir/scripts/pi-codex-channel" glm52 test --prompt x --dry-run)
[[ "$override_output" == *'model=example/model'* ]]

print 'smoke test passed'
