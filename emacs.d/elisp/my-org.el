(assq-delete-all 'org package--builtins)
(assq-delete-all 'org package--builtin-versions)


(use-package org-journal
  :ensure t
  :init
  (add-to-list 'linum-disabled-modes-list 'org-journal-mode)
  (setq org-journal-file-type 'monthly)
  (setq org-journal-file-format "%Y-%m.org")
  (setq org-journal-date-format "%A, %d.%m.%Y"))

(use-package org
  :ensure t
  :defer t
  :config
  (load "org/config.el"))

(provide 'my-org)
