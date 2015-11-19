(setq make-backup-files nil)
(setq inhibit-splash-screen t)
(global-font-lock-mode 1)
(transient-mark-mode 1)
(savehist-mode 1)
(setq vc-follow-symlinks t)
(setq ring-bell-function 'ignore)

(add-hook 'emacs-lisp-mode-hook 
	  '(lambda () 
	     (local-set-key (kbd "RET") 'newline-and-indent)))

(require 'package)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(package-initialize)

(load-file "~/.emacs.d/elisp/org-config/config.el")

(add-to-list 'load-path "~/.emacs.d/elisp")
(add-to-list 'load-path "~/.emacs.d/elisp/cucumber.el")

(require 'feature-mode)
(add-to-list 'auto-mode-alist '("\.feature$" . feature-mode))

(add-to-list 'load-path "~/.emacs.d/elisp/rspec-mode")
(require 'rspec-mode)


;;(setq auto-indent-on-visit-file t) ;; If you want auto-indent on for files
;;(require 'auto-indent-mode)
;;(auto-indent-global-mode)
;;(setq-default indent-tabs-mode nil)

(add-to-list 'load-path "~/.emacs.d/elisp/emacs-elixir")
(require 'elixir-mode)

(require 'linum-off)

(global-linum-mode)
(column-number-mode)
(delete-selection-mode 1)

(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

(setq ido-everywhere t)
(setq ido-max-directory-size 100000)
(ido-mode 'both)
(setq ido-default-file-method 'selected-window)
(setq ido-default-buffer-method 'selected-window)

(require 'smex)
(smex-initialize)

(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "C-x x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)

(setq tramp-mode nil)

(add-to-list 'load-path "~/.emacs.d/elisp/rust-mode")
(autoload 'rust-mode "rust-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))


(require 'package)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)

(if (file-exists-p "~/.emacs.local")
    (load "~/.emacs.local"))

