(assq-delete-all 'org package--builtins)
(assq-delete-all 'org package--builtin-versions)
(require 'linum-off)


(use-package org
  :ensure t
  :defer t
  :config
  (load "org/config.el")
  (global-linum-mode))

(provide 'my-org)
