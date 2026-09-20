# emacs.d

A deliberately small Emacs configuration for testing an agent-first development
workflow.

The first milestone is intentionally limited to:

- built-in `project.el` / `xref`;
- Magit;
- Dev Containers;
- OpenAI Codex inside Emacs;
- Claude Code with Emacs MCP tools.

## Requirements

- Emacs 30 or newer
- `git` in `PATH`
- Docker / Docker Compose as required by your project
- `devcontainer` CLI on the **host** for projects using Dev Containers
- `codex` and `claude` either:
  - inside the project's devcontainer, or
  - on the host for non-devcontainer projects

Install the official Dev Container CLI on the host, for example:

```sh
npm install -g @devcontainers/cli
```

The configuration uses Emacs 30's built-in `use-package :vc` support for the
two agent integrations. Other package dependencies are installed from
GNU ELPA, NonGNU ELPA, or MELPA on first startup.

## Dev Container model

Emacs itself runs on the host and edits the normal host-mounted working tree.

For a project containing either:

```text
.devcontainer/devcontainer.json
```

or:

```text
.devcontainer.json
```

the generated Codex and Claude wrappers run:

```sh
devcontainer exec --workspace-folder "$PWD" codex ...
devcontainer exec --workspace-folder "$PWD" claude ...
```

For projects without a devcontainer definition they fall back to:

```sh
codex ...
claude ...
```

This means the same Emacs configuration works for both containerized and
host-native projects.

The `devcontainer.el` package is also installed. It can manage project
devcontainers from Emacs and route normal `compile` commands into the
container.

## Install

Clone this repository as your Emacs configuration directory.

Typical Linux/macOS layout:

```sh
git clone https://github.com/novg/emacs.d.git ~/.emacs.d
```

If your Emacs uses `~/.config/emacs`, clone there instead.

Start Emacs. The first launch may download package metadata and dependencies.

## First checks

From a devcontainer project root, first verify on the host:

```sh
devcontainer exec --workspace-folder . codex --version
devcontainer exec --workspace-folder . claude --version
```

Then inside Emacs:

1. Open the project.
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
