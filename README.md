# emacs.d

A deliberately small Emacs configuration for testing an agent-first development
workflow.

## Current architecture

Emacs runs on the host.

The ALMA development environment is different from the usual "one devcontainer
per repository" model:

- one shared devcontainer lives at `$ALMA_PROJECTS/repos/alma/.devcontainer`;
- that path is a symlink to `$ALMA_PROJECTS/containers/dev-env/devcontainer`;
- the whole `$ALMA_PROJECTS` tree is bind-mounted into the container at the
  same absolute path;
- many Git repositories live inside that tree;
- VS Code selects a working subset through a multi-root workspace.

Emacs therefore does **not** search for `.devcontainer.json` in every project.

Instead, any Codex or Claude process started from a directory under
`$ALMA_PROJECTS` is launched through the one shared ALMA devcontainer while
preserving the current repository directory inside the container.

Conceptually:

```text
host Emacs
   |
   +-- project A ------+
   +-- project B ------+--> shared alma-dev container
   +-- project C ------+
```

Each repository remains an independent Emacs `project.el` project. The shared
container is infrastructure, not the Emacs project root.

For directories outside `$ALMA_PROJECTS`, Codex and Claude fall back to local
host executables.

## Requirements

- Emacs 30 or newer
- `git`
- Docker / Docker Compose
- `devcontainer` CLI on the host
- `ALMA_PROJECTS` available in the environment inherited by Emacs
- `codex`, `claude`, `dotnet`, etc. installed in the shared devcontainer

Install the Dev Container CLI on the host, for example:

```sh
npm install -g @devcontainers/cli
```

## How agent launching works

If Emacs is currently in:

```text
$ALMA_PROJECTS/repos/some-project
```

the generated wrapper effectively does:

```sh
devcontainer exec \
  --workspace-folder "$ALMA_PROJECTS/repos/alma" \
  sh -lc 'cd "$CURRENT_PROJECT"; exec codex ...'
```

Claude works the same way.

This is important because `devcontainer exec --workspace-folder` identifies
the shared container, while the explicit `cd` restores the actual repository
that the agent should work on.

## Multi-root workflow in Emacs

There is no need to reproduce a VS Code `.code-workspace` file just to use
multiple repositories.

Emacs can keep every Git repository as its own `project.el` project and switch
between them with `project-switch-project`. Codex and Claude sessions stay
project-aware while still using the same shared container.

We can add a higher-level "workspace" layer later if we want one command to open
a named set of related projects, buffers and tabs.

## First checks

On the host:

```sh
echo "$ALMA_PROJECTS"
devcontainer exec --workspace-folder "$ALMA_PROJECTS/repos/alma" \
  sh -lc 'command -v codex && command -v claude && command -v dotnet'
```

Inside Emacs:

1. Open a file in one ALMA repository.
2. Run `M-x codex`.
3. Run `M-x claude-code-ide-check-status`.
4. Run `M-x claude-code-ide`.
5. Open a file in another ALMA repository and repeat.
6. Use `C-x g` for Magit.

## Philosophy

Keep Emacs native on the host and keep the development toolchain in the shared
devcontainer. Add more integration only when a real workflow need appears.
