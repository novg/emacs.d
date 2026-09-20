;;; init.el --- Minimal Emacs setup for coding agents -*- lexical-binding: t; -*-

;; This configuration intentionally starts small.  The first milestone is a
;; comfortable project/Git workflow with Codex and Claude Code inside Emacs.

(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(package-initialize)

;; Needed only on a fresh installation (or after deleting package metadata).
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)

;; Keep Customize-generated settings out of init.el.
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; Git.
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; Shared pure-Elisp terminal backend.  Claude Code uses it directly; Codex
;; keeps it available as a dependency even though we prefer app-server.
(use-package eat
  :ensure t)

;; OpenAI Codex.
;;
;; C-c x     Codex command map
;; M-x codex Start a Codex session for the current project
(use-package codex
  :vc (:url "https://github.com/benthamite/codex" :rev :newest)
  :after eat
  :custom
  (codex-terminal-backend 'app-server)
  :bind-keymap
  ("C-c x" . codex-command-map))

;; Claude Code.
;;
;; C-c C-'                 Claude Code transient menu
;; M-x claude-code-ide     Start Claude Code for the current project
;;
;; The MCP tools expose Emacs project/xref/imenu/tree-sitter information to
;; Claude Code, which is the main reason we use the IDE integration.
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :after eat
  :custom
  (claude-code-ide-terminal-backend 'eat)
  :bind
  ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

(provide 'init)
;;; init.el ends here
