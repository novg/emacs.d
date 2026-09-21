# emacs.d

Небольшая конфигурация Emacs для эксперимента с agent-first C# workflow.

## Архитектура

Emacs работает полностью на хосте. Никаких `devcontainer exec`, `alma-dev-instance`
или контейнерных wrapper-ов больше нет.

```text
Emacs
├── Magit -> host Git / GPG / SSH
├── Eglot -> host csharp-ls
├── Codex -> host codex_proxy -> mise Codex
└── Claude Code -> host Claude CLI

Docker
└── db / adminneo / saa / saa-front
    управляются отдельным novg/alma-dev
```

Toolchain и инфраструктуру предоставляет `novg/alma-dev`. Этот репозиторий отвечает только
за Emacs.

## Requirements

- Emacs 30+;
- выполненный `alma-dev/bootstrap.sh`;
- `~/.local/bin` и mise toolchain, созданные `alma-dev`;
- `csharp-ls` для C#;
- Codex и Claude Code из того же mise toolchain.

GUI Emacs сам добавляет mise shims и `~/.local/bin` в `exec-path`, поэтому не зависит от
запуска из терминала. Простые переменные из `~/.config/alma-dev/env` тоже подхватываются
напрямую.

## C#

C# buffers автоматически запускают Eglot с `csharp-ls`.

```text
M-x eglot
M-x eglot-reconnect
M-x xref-find-definitions
M-x xref-find-references
```

## Agents

```text
M-x codex
C-c x

M-x claude-code-ide-check-status
M-x claude-code-ide
C-c C-'
```

Codex предпочитает `codex_proxy` из `alma-dev`, если wrapper установлен, иначе запускает
обычный `codex`. Claude Code запускается напрямую на хосте.

## Git

`C-x g` открывает Magit. Git, SSH и GPG полностью host-native, поэтому подписанные commits и
credentials используют обычную конфигурацию пользователя без forwarding в контейнер.

## Philosophy

Редактор и development toolchain находятся на одной стороне границы — на хосте.
Контейнеры используются только как runtime infrastructure.
