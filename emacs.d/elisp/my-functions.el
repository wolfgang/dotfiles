(defun my-clojure-before-save-hook ()
    (add-hook 'before-save-hook 'my-clojure-format-buffer nil 'local))

(defun my-clojure-format-buffer ()
  (interactive)
  (let ((p (point)))
    (progn
      (cider-format-buffer)
      (clojure-sort-ns)
      (goto-char p))))

(defun my-bloom-backend-start ()
  (interactive)
  (cider-interactive-eval "(do (load-file \"repl/miro/lib.clj\") (lib/start))"))


(defun my-bloom-user-data-restart ()
  (interactive)
  (progn
    (cider-quit)
    (cider-jack-in `())))

(defun my-bloom-backend-stop ()
  (interactive)
  (cider-interactive-eval "(dev/stop)"))

(defun my-bloom-backend-restart ()
  (interactive)
  (my-bloom-backend-stop)
  (run-with-idle-timer 0.3 nil 'my-bloom-backend-start))

(defun my-delete-line-keep-column-position ()
  "Delete current line and keep point at current column."
  (interactive)
  (let ((column-index (current-column)))
    (kill-whole-line)
    (move-to-column column-index)))

(defun my-delete-region-or-line ()
  "Delete region if active or current line."
  (interactive)
  (if (use-region-p)
      (call-interactively 'kill-region)
    (call-interactively 'my-delete-line-keep-column-position)))

(defun my-rustic-mode-auto-save-hook ()
  "Enable auto-saving in rustic-mode buffers."
  (when buffer-file-name
    (setq-local compilation-ask-about-save nil)))

(defun my-consult-ripgrep (&optional dir initial)
  (interactive "P")
  (consult-ripgrep dir (ivy-thing-at-point)))

(fset 'my-org-daily-agenda
      (kmacro-lambda-form [f12 ?d ?l] 0 "%d"))

(provide `my-functions)
