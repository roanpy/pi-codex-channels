<div align="center">
  <h1>Pi Codex Channels</h1>
  <p><strong>Delegate bounded tasks from Codex Desktop to named Pi channels with persistent, resumable sessions.</strong></p>

  English · [简体中文](README.zh-CN.md)

  [![Status: Beta](https://img.shields.io/badge/status-beta-2563eb.svg)](#project-status)
  [![Agent Skill](https://img.shields.io/badge/Agent%20Skill-compatible-111827.svg)](SKILL.md)
  [![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
</div>

## The problem it solves

Codex Desktop can delegate to subagents, but subagent processes are ephemeral: each spawn starts from scratch, and routing a specific task to a specific external model requires custom configuration. Pi Codex Channels gives each (Codex task × model role) pair a **named, persistent Pi session** that survives individual calls, so you can:

- Send a bounded task to a specific model and get the result inline.
- Follow up later in the same session with full history intact.
- Hand a stalled session to a different model without losing context.
- Fork a channel from an older Codex task into a new one.

## How it works

The launcher runs from a terminal opened by Codex Desktop and derives `CODEX_THREAD_ID` automatically. It creates a private session directory per Codex task under `~/.pi/agent/codex-sessions/<thread-id>/`, keyed by the thread's first 13 characters.

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

# From a Codex Desktop terminal:
./scripts/pi-codex-channel glm52 "payments" \
  --prompt "Implement the confirmed payment retry fix and run the related tests."
```

To install as a Codex skill, copy the repository contents into `~/.codex/skills/pi-codex-channels/`.

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
- Session deletion moves to macOS Trash only, requires explicit `--yes`, and refuses while any related process is alive.
- Session directories and runtime markers are created `700`/`600`.
- No API keys anywhere: models are resolved through Pi's own local provider configuration.

## Manage sessions

```bash
./scripts/pi-codex-sessions list
./scripts/pi-codex-sessions delete <full-codex-thread-id> --yes
```

## Requirements

- macOS or Linux with [Pi](https://github.com/badlogic/lemern) (the `pi` coding agent CLI) on `PATH`. On Windows, run inside WSL.
- Codex (Desktop or CLI), with commands run from a terminal that exposes `CODEX_THREAD_ID`; **or** any other shell (including a Claude Code terminal), where the launcher falls back to a stable project id derived from the git repository root. Session deletion moves to the macOS Trash or the freedesktop Trash on Linux.
- `tmux` only for `--interactive` channels.
- `jq` only for `pi-codex-sessions list`.

## Platform notes

- **Codex and Claude Code (and any shell).** Under Codex the session model keys off `CODEX_THREAD_ID`. Outside Codex it keys off the git repository root, giving one persistent channel namespace per project. See [integrations/claude-code.md](integrations/claude-code.md) for a ready-made Claude Code skill.
- Session history and runtime state live under `~/.pi/agent/codex-sessions/` on every platform.

## Project status

Beta. The one-shot delegation path is in daily use by the author; the interactive tmux path and the reaper integration work but have seen less mileage.

## License

[MIT](LICENSE)
