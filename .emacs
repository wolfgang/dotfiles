(setq make-backup-files)
(setq inhibit-splash-screen t)
(global-font-lock-mode 1)
(transient-mark-mode 1)
(savehist-mode 1)

(add-hook 'emacs-lisp-mode-hook 
	  '(lambda () 
	     (local-set-key (kbd "RET") 'newline-and-indent)))

(setq ring-bell-function 'ignore)

(load-file "~/.emacs.d/elisp/org-config/config.el")

(add-to-list 'load-path "~/.emacs.d/elisp/cucumber.el")

(require 'feature-mode)
(add-to-list 'auto-mode-alist '("\.feature$" . feature-mode))
