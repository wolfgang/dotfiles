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

(use-package which-key
  :ensure t
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.5
        which-key-idle-secondary-delay 0.5)
  (which-key-setup-side-window-bottom))

(use-package company
  :ensure t
  :diminish company-mode
  :bind (:map company-active-map
              ("<escape>" . company-abort))
  :hook ((after-init . global-company-mode))
  :config
  ;; respect case when inserting into buffer, ignore when searching for candidates
  (setq company-dabbrev-downcase nil
        company-dabbrev-ignore-case 'yes
        company-show-numbers t))

(use-package cider
  :ensure t
  :defer t
  :bind (("C-<return>" . cider-format-buffer))
  :init
  (setq cider-repl-pop-to-buffer-on-connect nil
        cider-repl-use-pretty-printing t)
  :config
  (add-hook 'clojure-mode-hook
            (lambda () (add-hook 'before-save-hook 'cider-format-buffer nil 'local)))
  (add-hook 'clojure-mode-hook
            (lambda () (add-hook 'before-save-hook 'clojure-sort-ns nil 'local)))
  (add-hook 'cider-mode-hook #'eldoc-mode)
  (add-hook 'cider-mode-hook #'cider-auto-test-mode)
  (add-hook 'cider-mode-hook #'cider-company-enable-fuzzy-completion)

  (use-package cider-eval-sexp-fu
    :ensure t)
  (use-package helm-cider
    :ensure t
    :config (helm-cider-mode)))

(use-package clojure-mode
  :ensure t
  :defer t
  :config
  (use-package clj-refactor
    :ensure t
    :diminish clj-refactor-mode
    :init
    (setq cljr-warn-on-eval nil)
    (add-hook 'clojure-mode-hook 'clj-refactor-mode))
  (use-package flycheck-clj-kondo
    :ensure t))


(setq custom-file "~/.emacs.local")

(if (file-exists-p "~/.emacs.local")
    (load "~/.emacs.local"))
