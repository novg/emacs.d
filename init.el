;;; init.el --- Minimal host-native setup for coding agents -*- lexical-binding: t; -*-

(require 'package)
(require 'project)
(require 'subr-x)

;;;; Host environment

(defun my/load-dotenv (file)
  "Load simple NAME=value lines from FILE into Emacs' process environment."
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (dolist (line (split-string (buffer-string) "\n" t))
        (unless (or (string-prefix-p "#" line)
                    (string-empty-p (string-trim line)))
          (when (string-match "\\`\\([A-Za-z_][A-Za-z0-9_]*\\)=\\(.*\\)\\'" line)
            (setenv (match-string 1 line) (match-string 2 line))))))))

(my/load-dotenv (expand-file-name "~/.config/alma-dev/env"))

(dolist (dir (list (expand-file-name "~/.local/bin")
                   (expand-file-name "~/.local/share/mise/shims")
                   (expand-file-name "~/.dotnet/tools")))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir path-separator (or (getenv "PATH") "")))))

(setenv "DOTNET_ROOT" (expand-file-name "~/.local/share/mise/dotnet-root"))
(when (file-readable-p "/etc/ssl/certs/ca-certificates.crt")
  (setenv "NODE_EXTRA_CA_CERTS" "/etc/ssl/certs/ca-certificates.crt"))

;; Prototype-render skills use globally installed puppeteer-core. GUI Emacs does
;; not necessarily inherit a login shell's NODE_PATH, so derive it from the same
;; mise-managed npm that is already on exec-path.
(when-let ((npm (executable-find "npm")))
  (condition-case nil
      (when-let ((node-path (car (process-lines npm "root" "-g"))))
        (setenv "NODE_PATH" node-path))
    (error nil)))

;;;; Packages

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(require 'use-package)

(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;;;; Git

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;;;; Terminal

(use-package eat
  :ensure t)

;;;; C#

(use-package csharp-mode
  :ensure t
  :mode "\\.cs\\'"
  :hook (csharp-mode . eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) . ("csharp-ls"))))

;;;; Agents

(defconst my/codex-program
  (or (executable-find "codex_proxy")
      (executable-find "codex")
      "codex")
  "Host-native Codex executable.")

(defconst my/claude-program
  (or (executable-find "claude") "claude")
  "Host-native Claude Code executable.")

(use-package codex
  :vc (:url "https://github.com/benthamite/codex" :rev :newest)
  :after eat
  :custom
  (codex-program my/codex-program)
  (codex-terminal-backend 'app-server)
  :bind-keymap
  ("C-c x" . codex-command-map))

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :after eat
  :custom
  (claude-code-ide-cli-path my/claude-program)
  (claude-code-ide-terminal-backend 'eat)
  :bind
  ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

(provide 'init)
;;; init.el ends here
