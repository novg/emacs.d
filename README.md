# emacs.d

A deliberately small Emacs configuration for testing an agent-first development
workflow.

The first milestone is intentionally limited to:

- built-in `project.el` / `xref`;
- Magit;
- OpenAI Codex inside Emacs;
- Claude Code with Emacs MCP tools.

## Requirements

- Emacs 30 or newer
- `git` in `PATH`
- `codex` CLI installed and authenticated
- `claude` (Claude Code) CLI installed and authenticated

The configuration uses Emacs 30's built-in `use-package :vc` support for the
two agent integrations. Other package dependencies are installed from
GNU ELPA, NonGNU ELPA, or MELPA on first startup.

## Install

Clone this repository as your Emacs configuration directory.

Typical Linux/macOS layout:

```sh
git clone https://github.com/novg/emacs.d.git ~/.emacs.d
```

If your Emacs uses `~/.config/emacs`, clone there instead.

Start Emacs. The first launch may download package metadata and dependencies.

## First checks

Inside Emacs:

1. Open a Git project.
2. Run `M-x codex`.
3. Press `C-c x` to explore the Codex command map.
4. Run `M-x claude-code-ide-check-status`.
5. Run `M-x claude-code-ide`.
6. Press `C-c C-'` for the Claude Code menu.
7. Press `C-x g` for Magit.

Codex is configured to use its native `app-server` backend.

Claude Code uses `eat` and enables the Emacs MCP tools, giving Claude access
to project/xref/imenu/tree-sitter-aware operations exposed by
`claude-code-ide.el`.

## Philosophy

Do not turn this into a large distribution yet. Add configuration only when a
real workflow problem appears during daily use.
