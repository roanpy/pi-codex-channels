---
name: pi-codex-channels
description: Start or resume named Pi channels bound to the current Codex Desktop task. Use only when the user explicitly asks for Codex-Pi, a Pi channel, or this skill; do not use merely because the user requests a subagent or names an external model.
---

# Pi Codex Channels

## Activation boundary

- Treat Codex-Pi as opt-in only. Start it only when the user explicitly says to use Codex-Pi, a Pi channel, or `pi-codex-channels`.
- A request for a subagent or an external model is not permission to use Codex-Pi. Use the requested native Codex collaboration model when available; otherwise report that it is unavailable and ask before falling back to Pi.
- Do not let this skill take over ordinary delegation or act as the default external-model adapter.

Run the bundled launcher from a terminal opened by Codex Desktop. It derives the current `CODEX_THREAD_ID`, creates a private Pi session directory for that exact Codex task, and uses its first 13 characters in session IDs and display names. On later launches it opens the exact existing session file, even if the terminal's working directory changed.

The default lifecycle is one-shot: delegated `--prompt` work runs directly and exits when complete, while its JSONL session history is retained for later continuation. Persistent interactive channels are opt-in with `--interactive` and run inside a stable `pi-cdx-<thread>-<channel>` tmux session.

```zsh
./scripts/pi-codex-channel glm52 --interactive
./scripts/pi-codex-channel ds4pro "Payment refactor" --interactive
```

When Codex delegates work, pass the complete task with `--prompt`; the launcher runs Pi non-interactively, records the result in the named channel, removes its transient runtime marker, and returns output to Codex. A blank invocation is rejected by default. For a human-driven persistent TUI, pass `--interactive` explicitly.

```zsh
./scripts/pi-codex-channel glm52 "payments" \
  --prompt "Implement the confirmed payment retry fix and run the related tests; do not expand scope."
```

## Choose a channel

Pick the channel from the requested work when no model is specified:

- Plan a complex change, implement core logic, or carry out a cross-module refactor: `glm52`.
- Perform a deep audit, security/regression review, causal analysis, architecture reasoning, or write a technical design/long-form article: `ds4pro`.
- Quickly locate code, summarize facts, triage an issue, or draft a short code-derived document: `v4flash`.
- Analyze screenshots, mockups, visual regressions, or image-dependent UI work: run `m3`, then let `v4flash` temporarily take over the M3 session.
- Challenge a high-impact result independently before release: `kimi26`.
- One clearly bounded difficult architecture or coding task, explicitly requested: `kimi3`.

Only mention the selected channel briefly. Do not ask the user to choose a model unless the task genuinely spans multiple roles. Prefer one channel per task.

## Configure models

Each channel maps to a `provider/model` that your local Pi installation must already know. The script ships with built-in defaults that match the original author's subscriptions; override any channel without editing the script:

```zsh
cp scripts/channels.conf.example scripts/channels.conf
chmod 600 scripts/channels.conf
# edit scripts/channels.conf, then:
export PI_CODEX_CHANNELS_CONF=/path/to/channels.conf   # optional; default is channels.conf next to the script
```

Run `pi models` to list providers and models configured on your machine. Channels without an override keep the built-in default.

- Treat the configured mapping as authoritative. Do not inspect Pi's model registry, discover additional models, or auto-select a different provider/model merely because it is available.
- Only inspect model availability after a concrete launch error. Retry transient transport failures with the configured model first; report the error and proposed fallback, and never switch silently.

## Session lifecycle

- One Codex task plus one channel maps to one logical Pi session. Repeated `--prompt` calls reuse that session's history, but each process exits after its response.
- Different channels stay in separate sessions; there is no global shared Pi session.
- Use `--continue-from` only for an explicit serial handoff or failure takeover. Use `--fork-from` when a new Codex task should branch from an older task without moving it.
- The launcher holds an atomic per-session lock. If the same channel is still running, wait or stop that verified process before retrying; never bypass the lock or run two writers against one JSONL.
- Exiting a Pi process does not delete its JSONL history. Never delete it merely because a one-shot call finished.
- In a new Codex task, fork a channel from an older task instead of moving it: `glm52 "continue payments" --fork-from <old-full-codex-thread-id> glm52`. The selected model may differ from the old channel.
- Keep all roles separate by default. Never run two models against the same Pi session concurrently.
- Do not use this launcher outside a Codex Desktop terminal: it intentionally fails when `CODEX_THREAD_ID` is absent.
- Do not launch a second Pi against a running tmux channel. Close or detach the existing `pi-cdx-*` channel first; one Pi process owns one session at a time.
- Do not place API keys in commands, prompts, names, or this skill. Pi uses its existing local provider configuration.

## Failure, quota, and handoff

- Treat transport/server failures as transient: `timeout`, connection reset, `5xx`, overload, and ordinary rate limiting may use Pi's configured exponential retry.
- Treat quota, balance, billing, subscription-limit, and authentication failures as terminal: `insufficient_quota`, `quota exceeded`, `out of budget`, `billing`, `401`, `402`, or `403` must not be retried. Report the provider, model, session key, error class, and whether a fallback is available. Never print or rotate credentials.
- After transient retries are exhausted, or after a terminal failure, inspect the session output and the working-tree diff before handing off. A request that may have partially written files must not be blindly replayed.
- For an authorized temporary takeover, switch serially with the existing history: `pi-codex-channel <replacement> "<topic>" --continue-from <failed-session-key> --prompt "Continue the unfinished part; verify existing changes first to avoid duplicate writes."`. Never run two models against the same session concurrently.
- The Codex parent owns the handoff decision and user notification. A fallback is continuation of the same bounded task, not a new objective or permission to expand scope.

## Audit budgets

For deep audits, require the model to state scope first. Default budget: 20 relevant file reads, 24 tool calls, and at most 8 prioritized findings. For cross-module impact checks, name the modules being checked. Default budget: 12 relevant file reads, 16 tool calls, and at most 6 impact items. A budget may be exceeded only after stating the concrete blocker.

## Manage categorized sessions

List only Codex-linked Pi session categories and their channel IDs:

```zsh
./scripts/pi-codex-sessions list
```

To remove one unused Codex task category, explicitly move it to macOS Trash:

```zsh
./scripts/pi-codex-sessions delete <full-codex-thread-id> --yes
```

Use `delete-current --yes` only when the current Codex task's Pi history is no longer needed. Never delete sessions automatically. The deletion command refuses to proceed while a related runtime marker, lock, tmux channel, or any unmapped direct Codex Pi process is still active.
