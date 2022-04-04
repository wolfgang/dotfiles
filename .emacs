(setq gc-cons-threshold (* 100 1024 1024))
(setq gc-cons-percentage 0.6)

(setq package-user-dir (locate-user-emacs-file "elpa"))
(setq package-archives
      '(("melpa-stable" . "https://stable.melpa.org/packages/")
        ("melpa"        . "https://melpa.org/packages/")
        ("gnu"          . "https://elpa.gnu.org/packages/")))
(setq package-archive-priorities
      '(("melpa-stable" . 15)
        ("melpa" . 10)
        ("gnu" . 0)))
(setq package-pinned-packages
      '((use-package . "melpa")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(setq use-package-verbose t)
(eval-when-compile
  (require 'use-package))

(require 'cl)
(setq make-backup-files nil)
(setq inhibit-splash-screen t)
(global-font-lock-mode 1)
(transient-mark-mode 1)
(savehist-mode 1)
(setq vc-follow-symlinks t)
(setq ring-bell-function 'ignore)
(tool-bar-mode -1)
(column-number-mode)
(delete-selection-mode 1)
(setq tramp-mode nil)

(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

(add-hook 'emacs-lisp-mode-hook 
	  '(lambda () 
	     (local-set-key (kbd "RET") 'newline-and-indent)))

(add-to-list 'load-path (concat user-emacs-directory "elisp"))

(require 'my-org)

(use-package solarized-theme
  :ensure t
  :init
  (setq solarized-scale-org-headlines nil))

(load-theme 'solarized-dark t)

(use-package helm
  :ensure t
  :diminish helm-mode
  :init
  (setq history-length 100 ; determines file-name-history; see helm-ff-file-name-history-use-recentf
        helm-split-window-default-side 'right
        helm-find-files-ignore-thing-at-point t)
  :bind
  (("M-x"     . helm-M-x)
   ("C-x C-f" . helm-find-files)
   ("C-x b"   . helm-mini)
   ("C-x C-r" . helm-recentf))
  :config
  (require 'tramp) ; otherwise void variable tramp-methods on projectile switch project
  (use-package helm-config)
  (helm-mode)
  (use-package helm-descbinds
    :ensure t
    :config (helm-descbinds-mode))
  (use-package helm-rg
    :ensure t))

(use-package magit
  :ensure t
  :bind (("<f6>" . magit-status)))

(setq custom-file "~/.emacs.local")

(if (file-exists-p "~/.emacs.local")
    (load "~/.emacs.local"))
