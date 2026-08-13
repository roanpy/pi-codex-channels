# Use from Claude Code

The launcher works outside Codex. When `CODEX_THREAD_ID` is absent, it derives
a stable project id from the git repository root (or the working directory
outside git), so every channel is scoped to the project you launched it from.
Session continuation, takeover, and forking behave exactly as under Codex.

## Install as a Claude Code skill

Clone the repository, then link the whole skill folder at user or project level:

    mkdir -p ~/.claude/skills
    ln -s /path/to/pi-codex-channels ~/.claude/skills/pi-codex-channels

Or for one project:

    mkdir -p .claude/skills
    ln -s /path/to/pi-codex-channels .claude/skills/pi-codex-channels

Claude Code loads the repository's canonical `SKILL.md`; there is no separate
Claude-specific copy to maintain. The skill is opt-in: ask explicitly for a Pi
channel, then Claude Code runs the launcher with the complete task in
`--prompt` mode.

## Directly from any shell

No Claude Code required — the launcher works in any terminal:

    cd your-project
    /path/to/pi-codex-channels/scripts/pi-codex-channel glm52 "review" \
      --prompt "Review the staged diff for regressions; read-only."

Repeat the same command later in the same project to continue the same
channel session. Use `pi-codex-sessions list` to see all project-scoped
channels (ids starting with `cc-`).
