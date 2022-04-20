(defun my-clojure-before-save-hook ()
    (add-hook 'before-save-hook 'my-clojure-format-buffer nil 'local))

(defun my-clojure-format-buffer ()
  (interactive)
  (progn
    (cider-format-buffer)
    (clojure-sort-ns)))

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

(provide `my-functions)
