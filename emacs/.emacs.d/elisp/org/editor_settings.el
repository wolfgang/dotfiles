(require 'elisp-format)

(setq make-backup-files nil)
(setq inhibit-splash-screen t)
(global-font-lock-mode 1)
(transient-mark-mode 1)
(savehist-mode 1)

(add-hook 'emacs-lisp-mode-hook 
	  '(lambda () 
	     (local-set-key (kbd "RET") 'newline-and-indent)))

(setq ring-bell-function 'ignore)

(add-hook 'org-mode-hook 
	  '(lambda () 
	     (auto-fill-mode 1) 
	     (setq fill-column 80))
	  'append)

(setq org-link-search-must-match-exact-headline nil)

(setq bookmark-sort-flag nil)

(setq org-support-shift-select t) 
