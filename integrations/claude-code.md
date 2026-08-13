# Use from Claude Code

The launcher works outside Codex. When `CODEX_THREAD_ID` is absent, it derives
a stable project id from the git repository root (or the working directory
outside git), so every channel is scoped to the project you launched it from.
Session continuation, takeover, and forking behave exactly as under Codex.

## As a Claude Code skill

Create `~/.claude/skills/pi-codex-channels/SKILL.md` (or
`.claude/skills/pi-codex-channels/SKILL.md` inside a project) with:

    ---
    name: pi-codex-channels
    description: Delegate a bounded task to a named Pi channel with a persistent, resumable session. Use when the user asks to route a task to a specific external model or a Pi channel.
    ---

    # Pi Codex Channels

    Delegate bounded tasks to named Pi channels. The launcher derives a stable
    project id from the git repository root, so sessions persist per project.

    Run from the project root:

        <path-to-repo>/scripts/pi-codex-channel <channel> "<topic>" --prompt "<full task>"

    Channels and model overrides are documented in the repository README.
    Always pass the complete task via `--prompt`; do not open a blank
    interactive session unless the user explicitly asks for `--interactive`.
    The launcher prints the Pi output; return it as your result.

Replace `<path-to-repo>` with the absolute path where you cloned
`pi-codex-channels`. Claude Code then translates "have glm52 review this
change" into the corresponding shell call.

## Directly from any shell

No Claude Code required — the launcher works in any terminal:

    cd your-project
    /path/to/pi-codex-channels/scripts/pi-codex-channel glm52 "review" \
      --prompt "Review the staged diff for regressions; read-only."

Repeat the same command later in the same project to continue the same
channel session. Use `pi-codex-sessions list` to see all project-scoped
channels (ids starting with `cc-`).
