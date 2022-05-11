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

(defun my-bloom-backend-stop ()
  (interactive)
  (cider-interactive-eval "(dev/stop)"))

(defun my-bloom-backend-restart ()
  (interactive)
  (progn
    (my-bloom-backend-stop)
    (my-bloom-backend-start)))

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

(provide `my-functions)
