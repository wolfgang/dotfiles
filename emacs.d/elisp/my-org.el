(assq-delete-all 'org package--builtins)
(assq-delete-all 'org package--builtin-versions)

(use-package org
  :ensure t
  :defer t)

(load "org/config.el")

(require 'linum-off)
(global-linum-mode)

(provide 'my-org)
