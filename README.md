<div align="center">
  <h1>Pi Codex Channels</h1>
  <p><strong>Delegate bounded tasks from coding agents to named Pi channels with persistent, resumable sessions.</strong></p>

  English · [简体中文](README.zh-CN.md)

  [![Status: Beta](https://img.shields.io/badge/status-beta-2563eb.svg)](#project-status)
  [![Agent Skill](https://img.shields.io/badge/Agent%20Skill-compatible-111827.svg)](SKILL.md)
  [![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
</div>

## The problem it solves

Coding agents can delegate to subagents, but those processes are often ephemeral, and routing a task to a specific external model requires custom configuration. Pi Codex Channels gives each host task or project plus model role a **named, persistent Pi session** that survives individual calls, so you can:

- Send a bounded task to a specific model and get the result inline.
- Follow up later in the same session with full history intact.
- Hand a stalled session to a different model without losing context.
- Fork a channel from an older Codex task into a new one.

## How it works

Under Codex, the launcher uses `CODEX_THREAD_ID` when the host exposes it. In every other shell it derives a stable project id from the Git `origin` URL, falling back to the repository or directory name when no origin exists. It never hashes your absolute local path. It creates a private session directory under `~/.pi/agent/codex-sessions/<task-or-project-id>/`.

Two lifecycle modes:

| Mode | Flag | Behavior |
| --- | --- | --- |
| One-shot (default) | `--prompt "<task>"` | Runs Pi non-interactively, prints the result, exits. Session JSONL is retained for continuation. |
| Interactive (opt-in) | `--interactive` | Opens a persistent Pi TUI inside a named tmux session (`pi-cdx-<thread>-<channel>`). |

## Quick start

```bash
git clone https://github.com/roanpy/pi-codex-channels pi-codex-channels
cd pi-codex-channels

# Point channels at models your Pi installation knows:
cp scripts/channels.conf.example scripts/channels.conf
chmod 600 scripts/channels.conf
# edit scripts/channels.conf — run "pi models" to see what is configured

# From the target project (Codex, Claude Code, or any shell):
./scripts/pi-codex-channel glm52 "payments" \
  --prompt "Implement the confirmed payment retry fix and run the related tests."
```

## Host integration

The launcher itself works from any local agent that can run shell commands. Native `SKILL.md` discovery is confirmed for:

| Host | Install the skill |
| --- | --- |
| Codex | `ln -s /path/to/pi-codex-channels ~/.codex/skills/pi-codex-channels` |
| Claude Code | `ln -s /path/to/pi-codex-channels ~/.claude/skills/pi-codex-channels` |
| Amp | `ln -s /path/to/pi-codex-channels ~/.config/agents/skills/pi-codex-channels` |
| Factory Droid | `ln -s /path/to/pi-codex-channels ~/.factory/skills/pi-codex-channels` |

Cursor, OpenCode, Gemini CLI, VS Code agents, and similar tools can call `scripts/pi-codex-channel` directly from their shell tool even when they do not load this `SKILL.md` automatically. Platform-specific task ids are not required: without `CODEX_THREAD_ID`, sessions are scoped to the git project.

Agents must keep the target project as the command working directory while invoking the launcher by its absolute or skill-relative path. Running from the skill repository would bind the session to the skill repository instead of the target project.

## Channels

Six named channels ship with built-in defaults matching the original author's subscriptions. Override any of them in `channels.conf` without editing the script:

| Channel | Built-in default | Intended role |
| --- | --- | --- |
| `glm52` | `example/model` | Planning and implementation |
| `ds4pro` | `example/model` | Deep audit, reasoning, long-form writing |
| `v4flash` | `example/model` | Fast recon and triage |
| `m3` | `example/model` | Screenshot/mockup visual analysis |
| `kimi26` | `example/model` | Independent adversarial review |
| `kimi3` | `example/model` | Bounded high-value architecture tasks |

You do not need these specific providers. Any `provider/model` pair your Pi knows works — see `scripts/channels.conf.example`.

## Session handoff

```bash
# Take over a failed channel's history with a different model:
./scripts/pi-codex-channel ds4pro "payments" --continue-from glm52 \
  --prompt "Continue the unfinished part; verify existing changes first."

# Fork a channel from an older Codex task into the current one:
./scripts/pi-codex-channel glm52 "payments follow-up" \
  --fork-from <old-full-codex-thread-id> glm52 \
  --prompt "Review the follow-up items from the earlier session."
```

## Safety properties

- Atomic per-session lock; refuses to run two writers against one session file.
- Refuses to start a one-shot task against a running interactive tmux channel.
- Session deletion moves to macOS Trash or Linux system Trash, requires explicit `--yes`, and refuses while any related process is alive. On Linux it requires `gio` (GLib) and refuses deletion when safe Trash support is unavailable.
- Session directories and runtime markers are created `700`/`600`.
- No API keys anywhere: models are resolved through Pi's own local provider configuration.

## Manage sessions

```bash
./scripts/pi-codex-sessions list
./scripts/pi-codex-sessions delete <full-codex-thread-id> --yes
```

## Requirements

- macOS or Linux with [Pi](https://github.com/earendil-works/pi) (the `pi` coding agent CLI) and `zsh` on `PATH`. On Windows, run inside WSL.
- Any local coding agent with a shell tool. When `CODEX_THREAD_ID` is present it provides task-level isolation; otherwise the launcher uses project-level isolation.
- `sha256sum` (GNU coreutils) or `shasum` for stable project ids.
- `tmux` only for `--interactive` channels.
- `jq` only for `pi-codex-sessions list`.
- `gio` (GLib) only for safe session deletion on Linux.

## Platform notes

- **Codex, Claude Code, Amp, Factory Droid, and any shell-capable local agent.** When `CODEX_THREAD_ID` is absent, the session model keys off the git repository root, giving one persistent channel namespace per project. See [integrations/claude-code.md](integrations/claude-code.md) for Claude Code notes.
- Session history and runtime state live under `~/.pi/agent/codex-sessions/` on every platform.

## Project status

Beta. The one-shot delegation path is in daily use by the author; the interactive tmux path and the reaper integration work but have seen less mileage.

## License

[MIT](LICENSE)
