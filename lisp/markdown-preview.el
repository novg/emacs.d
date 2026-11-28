;;; markdown-preview.el --- Local browser Markdown preview -*- lexical-binding: t; -*-

(defvar-local my/markdown-preview-process nil)
(defvar-local my/markdown-preview-directory nil)
(defvar-local my/markdown-preview-timer nil)

(defun my/markdown-preview-write (buffer)
  "Publish BUFFER's current text atomically to its private preview directory."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq my/markdown-preview-timer nil)
      (when my/markdown-preview-directory
        (let ((temporary (expand-file-name "next.md" my/markdown-preview-directory))
              (target (expand-file-name "document.md" my/markdown-preview-directory))
              (coding-system-for-write 'utf-8-unix))
          (save-restriction
            (widen)
            (write-region (point-min) (point-max) temporary nil 'silent))
          (rename-file temporary target t))))))

(defun my/markdown-preview-changed (&rest _)
  (when (timerp my/markdown-preview-timer)
    (cancel-timer my/markdown-preview-timer))
  (setq my/markdown-preview-timer
        (run-with-idle-timer 0.4 nil #'my/markdown-preview-write (current-buffer))))

(defun my/markdown-preview-stop ()
  "Stop this buffer's local preview and delete its temporary snapshot."
  (interactive)
  (remove-hook 'after-change-functions #'my/markdown-preview-changed t)
  (remove-hook 'kill-buffer-hook #'my/markdown-preview-stop t)
  (remove-hook 'change-major-mode-hook #'my/markdown-preview-stop t)
  (when (timerp my/markdown-preview-timer)
    (cancel-timer my/markdown-preview-timer))
  (setq my/markdown-preview-timer nil)
  (when (processp my/markdown-preview-process)
    (set-process-sentinel my/markdown-preview-process #'ignore)
    (when (process-live-p my/markdown-preview-process)
      (delete-process my/markdown-preview-process)))
  (setq my/markdown-preview-process nil)
  (when my/markdown-preview-directory
    (delete-directory my/markdown-preview-directory t)
    (setq my/markdown-preview-directory nil)))

(defun my/markdown-preview-filter (process chunk)
  (let ((output (concat (or (process-get process 'output) "") chunk)))
    (process-put process 'output output)
    (when (string-match "http://127\\.0\\.0\\.1:[0-9]+/[A-Za-z0-9_-]+/" output)
      (let ((url (match-string 0 output)))
        (process-put process 'url url)
        (set-process-filter process #'ignore)
        (browse-url url)))))

(defun my/markdown-preview-sentinel (process event)
  (unless (process-live-p process)
    (let ((buffer (process-get process 'source)))
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (when (eq process my/markdown-preview-process)
            (my/markdown-preview-stop)
            (message "Markdown preview stopped: %s" event)))))))

(defun my/markdown-preview ()
  "Open or reopen the local live preview for the current Markdown buffer."
  (interactive)
  (unless (derived-mode-p 'markdown-mode)
    (user-error "Open a Markdown buffer first"))
  (if (and (processp my/markdown-preview-process)
           (process-live-p my/markdown-preview-process))
      (when-let ((url (process-get my/markdown-preview-process 'url)))
        (browse-url url))
    (my/markdown-preview-stop)
    (dolist (program '("python3" "pandoc"))
      (unless (executable-find program)
        (user-error "Missing preview dependency: %s" program)))
    (let* ((dist (expand-file-name "node_modules/mermaid/dist" user-emacs-directory))
           (script (expand-file-name "scripts/markdown-preview.py" user-emacs-directory)))
      (unless (file-readable-p (expand-file-name "mermaid.esm.min.mjs" dist))
        (user-error "Install Mermaid: run npm install in %s" user-emacs-directory))
      (unless (file-readable-p script)
        (user-error "Missing preview script: %s" script))
      (setq my/markdown-preview-directory (make-temp-file "emacs-md-preview-" t))
      (condition-case err
          (progn
            (my/markdown-preview-write (current-buffer))
            (setq my/markdown-preview-process
                  (make-process
                   :name "markdown-preview"
                   :command (list "python3" script
                                  (expand-file-name "document.md" my/markdown-preview-directory)
                                  dist)
                   :connection-type 'pipe
                   :coding 'utf-8-unix
                   :noquery t
                   :filter #'my/markdown-preview-filter
                   :sentinel #'my/markdown-preview-sentinel))
            (process-put my/markdown-preview-process 'source (current-buffer))
            (add-hook 'after-change-functions #'my/markdown-preview-changed nil t)
            (add-hook 'kill-buffer-hook #'my/markdown-preview-stop nil t)
            (add-hook 'change-major-mode-hook #'my/markdown-preview-stop nil t))
        (error (my/markdown-preview-stop) (signal (car err) (cdr err)))))))

(provide 'markdown-preview-local)
;;; markdown-preview.el ends here
