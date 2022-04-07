(defun my-bloom-backend-start ()
  (interactive)
  (cider-interactive-eval "(do (load-file \"repl/miro/lib.clj\") (lib/start))"))

(defun my-bloom-backend-stop ()
  (interactive)
  (cider-interactive-eval "(dev/stop)"))

(provide `my-functions)
