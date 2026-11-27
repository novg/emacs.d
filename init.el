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

;;;; 
(setq frame-resize-pixelwise t)
(when window-system
  (set-frame-size (selected-frame) 160 35))

(when (display-graphic-p)
  (tool-bar-mode 0) ;; disable tool bar
  (menu-bar-mode 0) ;; disable menu bar
  (scroll-bar-mode 0)) ;; disable scroll bar

(setq inhibit-startup-screen t) ;; disable startup screen
;; (setq frame-title-format "GNU Emacs: %b")
;; (setq ring-bell-function 'ignore)
;; (setq-default indent-tabs-mode nil) ;; use spaces, not tabs, for indentation

(defalias 'yes-or-no-p 'y-or-n-p)

(setq scroll-step 1
      scroll-margin 1
      scroll-conservatively 10000)

;;;; show line numbers
(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(column-number-mode)
(global-hl-line-mode t) ;; Highlight current line


;;;; Runtime state

(setq create-lockfiles nil)

;; Refresh unmodified file buffers after external agent edits.
(global-auto-revert-mode 1)


(defconst my/cache-directory
  (expand-file-name "~/.cache/emacs/")
  "Directory for mutable Emacs runtime state.")

(defconst my/auto-save-directory
  (expand-file-name "auto-save/" my/cache-directory)
  "Directory for Emacs auto-save files.")

(defconst my/auto-save-list-directory
  (expand-file-name "auto-save-list/" my/cache-directory)
  "Directory for Emacs auto-save session metadata.")

(defconst my/backup-directory
  (expand-file-name "backups/" my/cache-directory)
  "Directory for Emacs backup files.")

(dolist (dir (list my/cache-directory
                   my/auto-save-directory
                   my/auto-save-list-directory
                   my/backup-directory))
  (make-directory dir t))

(setq auto-save-file-name-transforms
      `((".*" ,my/auto-save-directory t))
      auto-save-list-file-prefix
      (expand-file-name ".saves-" my/auto-save-list-directory)
      backup-directory-alist
      `(("." . ,my/backup-directory))
      project-list-file
      (expand-file-name "projects" my/cache-directory))

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

;;;; Completion and navigation

(use-package savehist
  :ensure nil
  :init
  (setq savehist-file (expand-file-name "history" my/cache-directory))
  (savehist-mode 1))

(use-package recentf
  :ensure nil
  :init
  (setq recentf-save-file (expand-file-name "recentf" my/cache-directory)
        recentf-max-saved-items 200)
  (recentf-mode 1))

(use-package vertico
  :ensure t
  :init (vertico-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

;; Install the integration before either client can check for it.
(use-package embark-consult
  :ensure t
  :defer t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer)
         ("C-s" . consult-line)
         ("M-g g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         ("M-g e" . consult-compile-error)
         ("M-y" . consult-yank-pop)
         ("C-c s r" . consult-ripgrep)
         ("C-c s f" . consult-find)
         ("C-c s h" . consult-history)))

(use-package marginalia
  :ensure t
  :init (marginalia-mode 1))

(use-package embark
  :ensure t
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim))
  :init (setq prefix-help-command #'embark-prefix-help-command))

;;;; In-buffer completion

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  :hook (prog-mode . corfu-mode))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-file t)
  (add-hook 'completion-at-point-functions #'cape-dabbrev t))

;;;; Appearance and ergonomics

(use-package modus-themes
  :ensure t
  :config
  (unless custom-enabled-themes
    (load-theme 'modus-operandi t)))

(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)
  (when marginalia-mode
    (nerd-icons-completion-marginalia-setup)))

(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package doom-modeline
  :ensure t
  :custom (doom-modeline-icon (display-graphic-p))
  :init (doom-modeline-mode 1))

(use-package which-key
  :ensure nil
  :custom (which-key-idle-delay 0.5)
  :config (which-key-mode 1))

(use-package helpful
  :ensure t
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))

(use-package diff-hl
  :ensure t
  :hook ((prog-mode . diff-hl-mode)
         (text-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode))
  :config
  (diff-hl-flydiff-mode 1)
  (with-eval-after-load 'magit
    (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

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
  (or (executable-find "codex")
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

;; Experimental ACP client; keep the existing specialized clients.
(use-package agent-shell
  :ensure t
  :commands (agent-shell)
  :bind ("C-c a" . agent-shell))

(provide 'init)
;;; init.el ends here
