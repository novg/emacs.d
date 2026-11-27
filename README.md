# emacs.d

Небольшая конфигурация Emacs для эксперимента с agent-first C# workflow.

## Архитектура

Emacs работает полностью на хосте. Никаких `devcontainer exec`, `alma-dev-instance`
или контейнерных wrapper-ов больше нет.

```text
Emacs
├── Magit -> host Git / GPG / SSH
├── Eglot -> host csharp-ls
├── Codex -> host codex -> mise Codex
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

Codex запускается напрямую на хосте через `codex` из mise toolchain.
Claude Code также запускается напрямую на хосте.

### Эксперимент: agent-shell (ACP)

Существующие клиенты Codex и Claude Code сохранены. `agent-shell` устанавливается через MELPA; ACP-адаптеры нужно отдельно установить на хосте с активным mise toolchain:

```sh
npm install -g @agentclientprotocol/claude-agent-acp @agentclientprotocol/codex-acp
mise reshim
command -v claude-agent-acp codex-acp
```

Перезапусти Emacs. Открой файл проекта и вызови `M-x agent-shell`, затем выбери Claude или Codex. `C-u M-x agent-shell` создаёт новую сессию. Проверь, что оба адаптера доступны через `M-: (executable-find "claude-agent-acp")` и аналогично для `codex-acp`. При необходимости настрой аутентификацию согласно [документации agent-shell](https://github.com/xenodium/agent-shell); доступ по подписке и возможные расходы зависят от провайдера и адаптера.

Для сравнения с существующими клиентами проверь получение задачи, вызов скиллов, планирование, редактирование, подтверждение действий и просмотр diff в Magit. Не запускай одновременно пишущих агентов в одном рабочем дереве.

## Editing defaults

Auto Revert обновляет неизменённые в Emacs файловые буферы после внешнего редактирования. Несохранённые изменения автоматически не перезаписываются; перед работой агента сохраняй буферы. Относительные номера строк включены только в `prog-mode`.

## Git

`C-x g` открывает Magit. Git, SSH и GPG полностью host-native, поэтому подписанные commits и
credentials используют обычную конфигурацию пользователя без forwarding в контейнер.

## Philosophy

Редактор и development toolchain находятся на одной стороне границы — на хосте.
Контейнеры используются только как runtime infrastructure.
