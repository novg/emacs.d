# emacs.d

A deliberately small Emacs configuration for testing an agent-first development
workflow.

## Architecture

Emacs runs on the host. Git/Magit also stays on the host so signing and host
credentials remain unchanged.

The ALMA development tree uses one canonical VS Code Dev Container plus optional
extra lightweight dev instances:

```text
canonical:
  alma-dev            <- VS Code Dev Containers

optional:
  alma-dev-adcs       <- Emacs / terminal workspace
  alma-dev-ace        <- Emacs / terminal workspace

shared:
  db / saa / adminneo / saa-front
```

All dev containers mount the full `$ALMA_PROJECTS` tree at the same absolute
path and reuse the same named tool caches.

## Choosing an instance from Emacs

By default, an ALMA project uses the canonical `alma-dev` container.

To bind the current Emacs project to an extra instance:

```text
M-x my/alma-use-instance
```

For example, from the ADCS repository enter:

```text
adcs
```

That persists a local mapping:

```text
/project/root    adcs
```

in `alma-instances` (ignored by Git).

After that, Codex and Claude launched from that project automatically use
`alma-dev-adcs`. Subdirectories inherit the longest matching project-root
mapping.

Useful commands:

```text
M-x my/alma-use-instance
M-x my/alma-show-instance
M-x my/alma-clear-instance
```

Clearing the mapping returns the project to the canonical VS Code container.

## Agent commands

```text
M-x codex
C-c x

M-x claude-code-ide-check-status
M-x claude-code-ide
C-c C-'
```

Codex uses its `app-server` backend. Claude Code uses `eat` plus Emacs MCP
tools.

## Frontend in an extra instance

The dev-env helper can publish a loopback-only Vite server without changing the
frontend repository:

```sh
alma-dev-instance start adcs --forward 8182:8082
```

Then run the frontend normally inside `alma-dev-adcs`; its existing
`127.0.0.1:8082` listener is proxied to host port `8182`.

The canonical VS Code workflow and its normal port forwarding remain unchanged.

## Requirements

- Emacs 30+
- Docker / Docker Compose
- official `devcontainer` CLI on the host
- `alma-dev-instance` installed by `dev-env/setup-host.sh`
- `ALMA_PROJECTS` inherited by Emacs
- Codex, Claude Code, dotnet and the rest of the toolchain inside the devcontainer

## Philosophy

Keep the editor native, keep the project toolchain containerized, and only add
workspace machinery when daily use proves it useful.
