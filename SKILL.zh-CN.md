---
name: pi-codex-channels
description: Start or resume named Pi channels bound to the current Codex Desktop task. Use only when the user explicitly asks for Codex-Pi, a Pi channel, or this skill; do not use merely because the user requests a subagent or names an external model.
---

# Pi Codex Channels

## Activation boundary

- Treat Codex-Pi as opt-in only. Start it only when the user explicitly says to use Codex-Pi, a Pi channel, or `pi-codex-channels`.
- A request for a subagent or an external model such as K3, DS4 Flash, GLM-5.2, or M3 is not permission to use Codex-Pi. Use the requested native Codex collaboration model when available; otherwise report that it is unavailable and ask before falling back to Pi.
- Do not let this skill take over ordinary delegation or act as the default external-model adapter.

Run the bundled launcher from a terminal opened by Codex Desktop. It derives the current `CODEX_THREAD_ID`, creates a private Pi session directory for that exact Codex task, and uses its first 13 characters in session IDs and display names. On later launches it opens the exact existing session file, even if the terminal's working directory changed.

The default lifecycle is one-shot: delegated `--prompt` work runs directly and exits when complete, while its JSONL session history is retained for later continuation. Persistent interactive channels are opt-in with `--interactive` and run inside a stable `pi-cdx-<thread>-<channel>` tmux session.

```zsh
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel ds4pro --interactive
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel v4flash --interactive
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel kimi26 --interactive
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel kimi3 --interactive
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel m3 --interactive
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel glm52 --interactive
```

Pass one optional topic solely to improve the display name:

```zsh
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel ds4pro "支付模块重构" --interactive
```

When Codex delegates work, pass the complete task with `--prompt`; the launcher runs Pi non-interactively, records the result in the named channel, removes its transient runtime marker, and returns output to Codex. A blank invocation is rejected by default. For a human-driven persistent TUI, pass `--interactive` explicitly.

```zsh
~/.codex/skills/pi-codex-channels/scripts/pi-codex-channel glm52 "支付模块" \
  --prompt "检查并实施已确认的支付重试修复，运行相关测试；不要扩大范围。"
```

## Route within Codex-Pi

After the user explicitly opts into Codex-Pi, choose the channel from the requested work when no model is specified:

- Plan a complex change, implement core logic, or carry out a cross-module refactor: `glm52`.
- Perform a deep audit, security/regression review, causal analysis, architecture reasoning, or write a technical design/long-form article: `ds4pro`.
- Check explicitly named cross-module impacts after an implementation: `glm52`.
- Quickly locate code, summarize facts, triage an issue, or draft a short code-derived document: `v4flash`.
- Analyze screenshots, mockups, visual regressions, or image-dependent UI work: run `m3`, then let `v4flash` temporarily take over the M3 session.
- Challenge a high-impact result independently before release: `kimi26`.

Only mention the selected channel briefly. Do not ask the user to choose a model unless the task genuinely spans multiple roles.

When acting for the user, always use `--prompt` with the actual task body. Do not open a blank interactive Pi TUI from a non-interactive Codex command; use `--interactive` only when the user explicitly requests a persistent channel.

Use `kimi3` only when the user explicitly asks for Kimi K3-256K to perform high-value architecture, implementation planning, or one clearly bounded difficult coding task. It is never part of the default route and must not be used for routine coding.

Keep every model in its own Pi session by default. For visual work, M3 first records text findings in its own session; then run `v4flash "<topic>" --continue-from m3` serially. Flash cannot read images, but it can temporarily take over M3's history, use the text findings to locate code, and implement scoped changes. Re-run M3 later in its own `m3` session for visual verification.

Prefer one channel per task. Start multiple channels only for the visual M3/V4 Flash workflow or when an independent final review materially reduces risk.

## Honor configured routing

- Treat the model/provider mapping in this skill and the user's local configuration as authoritative. Do not inspect Pi's model registry, discover additional models, or auto-select a different provider/model merely because it is available.
- Only inspect model availability after a concrete model/provider launch error. Retry transient transport failures with the configured model first; report the error and proposed fallback, and never switch silently.

## Session lifecycle

- One Codex task plus one model channel maps to one logical Pi session. Repeated `--prompt` calls reuse that session's history, but each process exits after its response.
- Different model channels stay in separate sessions; there is no global shared Pi session.
- Use `--continue-from` only for an explicit serial handoff or failure takeover. Use `--fork-from` when a new Codex task should branch from an older task without moving it.
- The launcher holds an atomic per-session lock. If the same channel is still running, wait or stop that verified process before retrying; never bypass the lock or run two writers against one JSONL.
- Exiting a Pi process does not delete its JSONL history. Never delete it merely because a one-shot call finished.

- `glm52` starts `example/model`.
- `ds4pro` starts `example/model`.
- `v4flash` starts `example/model` in its own fast-exploration session; it can temporarily take over another session with `--continue-from`.
- `kimi26` starts `example/model`.
- `kimi3` starts `example/model`.
- `m3` starts `example/model` for image-dependent work.
- Context windows: GLM-5.2 500K; DS4 Pro and V4 Flash 1M; Kimi K3-256K 256K; M3 1M; Kimi K2.6 256K. M3 and Kimi K3-256K support image input (no video). Give Kimi K2.6 the change set and evidence, not an entire large repository.
- Thinking levels: GLM-5.2, DS4 Pro, Kimi K2.6, and Kimi K3-256K use `high`; V4 Flash and M3 use `medium` to preserve speed.
- If a model repeatedly fails, explicitly start the replacement channel with `--continue-from <failed-session-key>` so it resumes the failed model's Pi history. Example: `ds4pro "支付模块" --continue-from glm52`.
- In a new Codex task, fork a channel from an older task instead of moving it. This preserves the original session and gives the new task its own continuation: `glm52 "继续支付模块" --fork-from <old-full-codex-thread-id> glm52`. The selected model may differ from the old channel; do not use this when you only need a same-task takeover.
- Keep all roles separate by default. Use `--continue-from` only for an explicit, serial handoff or failure takeover; never run two models against the same Pi session concurrently.
- The launcher appends a short role instruction for each channel; user instructions remain authoritative.
- Rely on the installed Pi Lens package for diagnostics and test monitoring; do not create a second monitoring channel.
- Keep the resulting Pi session separate from Codex's native task history. The shared short ID makes the relationship traceable.
- Do not use this launcher outside a Codex Desktop terminal: it intentionally fails when `CODEX_THREAD_ID` is absent.
- Do not launch a second Pi against a running tmux channel. Close or detach the existing `pi-cdx-*` channel first; one Pi process owns one session at a time.
- Do not place API keys in commands, prompts, names, or this skill. Pi uses its existing local provider configuration.

## Engineering execution discipline

- Default to one primary channel. Add an independent DS4 Pro or Kimi K2.6 review only for security-sensitive, cross-module, release-blocking, or disputed changes.
- Before changing files, state the goal, in-scope files, explicit edit authority, acceptance checks, and non-goals. Ask only when a missing decision materially changes the implementation.
- Implement the smallest complete change, run the relevant focused checks, then report changed files, commands run, results, and remaining uncertainty. Do not claim a check ran when it did not.
- On a provider failure, let configured retries finish, then resume the same channel with a short next-step instruction. Preserve the session; do not create parallel retries against the same session.

## Failure, quota, and handoff

- Treat transport/server failures as transient: `timeout`, connection reset, `5xx`, overload, and ordinary rate limiting may use Pi's configured exponential retry. The current Pi settings allow 8 application-level retries from a 1-second base delay; provider-level retries stay at 0 so the request is not retried twice.
- Treat quota, balance, billing, subscription-limit, and authentication failures as terminal: `insufficient_quota`, `quota exceeded`, `out of budget`, `billing`, `401`, `402`, or `403` must not be retried. Report the provider, model, session key, error class, and whether a fallback is available. Never print or rotate credentials.
- After transient retries are exhausted, or after a terminal quota/availability failure, inspect the session output and the working-tree diff before handing off. A request that may have partially written files must not be blindly replayed.
- For an authorized temporary takeover, switch serially with the existing history: `pi-codex-channel <replacement> "<topic>" --continue-from <failed-session-key> --prompt "继续未完成部分；先核对已有改动，避免重复写入。"`. Never run two models against the same session concurrently.
- Recommended handoffs: `glm52 → ds4pro` for deep reasoning or `v4flash` for triage; `ds4pro → glm52` for implementation; `v4flash → glm52` or `ds4pro`; `kimi3 → glm52`/`ds4pro`; `kimi26 → ds4pro`; `m3 → kimi3` for image-aware continuation. GLM/DS4/Flash cannot independently verify an image that only M3 saw; state that limitation and request the image again when visual evidence is required.
- The Codex parent owns the handoff decision and user notification. A fallback is continuation of the same bounded task, not a new objective or permission to expand scope.

## Audit budgets

For DS4 Pro deep audits, require it to state scope first. Default budget: 20 relevant file reads, 24 tool calls, and at most 8 prioritized findings. It may exceed a budget only after stating the concrete blocker.

For GLM-5.2 cross-module checks, name the modules being checked. Default budget: 12 relevant file reads, 16 tool calls, and at most 6 impact items. It may exceed a budget only after stating the concrete blocker.

## Manage categorized sessions

List only Codex-linked Pi session categories and their channel IDs:

```zsh
~/.codex/skills/pi-codex-channels/scripts/pi-codex-sessions list
```

To remove one unused Codex task category, explicitly move it to the system Trash (macOS Trash or freedesktop Trash on Linux):

```zsh
~/.codex/skills/pi-codex-channels/scripts/pi-codex-sessions delete <full-codex-thread-id> --yes
```

Use `delete-current --yes` only when the current Codex task's Pi history is no longer needed. Never delete sessions automatically.
The deletion command refuses to proceed while a related runtime marker, lock, tmux channel, or any unmapped direct Codex Pi process is still active.
