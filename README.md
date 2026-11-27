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

## Интерфейс и навигация

Пакеты устанавливаются автоматически через package.el. При ошибке 404 от MELPA
выполни `M-x package-refresh-contents` и перезапусти Emacs.

- Vertico, Orderless, Consult, Marginalia, Embark и Embark Consult: стандартный completion API вместо Helm.
- Corfu и Cape: автодополнение в программных буферах, включая Eglot и дополнительные CAPF.
- Diff-hl: индикаторы изменений Git и обновление после операций Magit.
- Modus Themes: встроенная светлая тема modus-operandi по умолчанию, если пользователь не выбрал другую.
- Doom Modeline, Nerd Icons, Nerd Icons Completion и Nerd Icons Dired: строка состояния и иконки.
- Which-key и Helpful: подсказки клавиш и расширенная справка.
- Savehist и Recentf: история minibuffer и недавние файлы в ~/.cache/emacs/.

Для корректного отображения иконок один раз выполни `M-x nerd-icons-install-fonts`,
затем перезапусти Emacs. Для поиска через Consult Ripgrep нужен `rg` на хосте
(в Debian: `sudo apt install ripgrep`). Тему можно выбрать через `M-x load-theme`,
например modus-vivendi для тёмного оформления.

| Клавиши | Действие |
| --- | --- |
| M-x | Выбор команды |
| C-x C-f | Открыть файл |
| C-x b | Consult Buffer |
| C-x p f | Файл проекта |
| C-s | Consult Line |
| M-g g | Перейти к строке |
| M-g i | Символы буфера |
| M-g e | Ошибки компиляции |
| M-y | История kill-ring |
| C-c s r | Ripgrep |
| C-c s f | Поиск файлов |
| C-c s h | История minibuffer |
| C-. | Embark Act |
| C-; | Embark DWIM |
| C-h f / v / k / x | Helpful |
| C-c h | Открыть памятку |
| C-c a | Agent Shell |
| C-c x | Codex |
| C-c C-' | Claude Code |
| C-x g | Magit |

Orderless позволяет вводить несколько частей имени через пробел в произвольном порядке.
Проверка после обновления: запусти Emacs, открой C# файл, проверь completion Eglot,
Consult Ripgrep, Dired, Magit и все три агентных интерфейса.

## Редактирование и рабочие пространства

- Markdown Mode: планы, документация и памятки.
- Avy, Expand Region и Ace Window: быстрая навигация, выделение и выбор окон.
- Wgrep: редактирование экспортированных результатов поиска.
- Undo-fu и Undo-fu-session: отмена, повтор и сохранение истории отмены в ~/.cache/emacs/undo/.
- Indent Bars и Rainbow Delimiters: визуальные подсказки в программных буферах.
- Встроенные Winner, Repeat, Save Place, Electric Pair, Show Paren, Pixel Scroll Precision и Tab Bar.
- Electric Pair включается локально в программных буферах, плавная прокрутка — только в графическом Emacs.

| Клавиши | Действие |
| --- | --- |
| C-c j | Avy: перейти к видимому тексту |
| C-c e | Расширить выделение |
| C-c w | Выбрать окно |
| C-c u | Undo |
| C-c r | Redo |
| C-c Left / Right | Winner: предыдущая / следующая конфигурация окон |
| C-x t 2 | Новая вкладка |
| C-x t o | Следующая вкладка |
| C-x t 0 | Закрыть вкладку |

Подробнее: [памятка по редактированию и рабочим пространствам](docs/cheatsheets/editing.md).

## Памятки

- [Agent-shell — работа с AI-агентами](docs/cheatsheets/agent-shell.md)
- [Magit — Git и ревью изменений](docs/cheatsheets/magit.md)
- [Редактирование и рабочие пространства](docs/cheatsheets/editing.md)

В Emacs нажми `C-c h` (или `M-x my/open-cheatsheet`), выбери памятку через Vertico и нажми `RET`. Новые Markdown-файлы в `docs/cheatsheets/` автоматически появятся в списке после добавления в локальную конфигурацию.

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
mise use -g 'npm:@agentclientprotocol/claude-agent-acp'
mise use -g 'npm:@agentclientprotocol/codex-acp'
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
