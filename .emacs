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
(global-font-lock-mode 1)
(transient-mark-mode 1)
(savehist-mode 1)
(tool-bar-mode -1)
(column-number-mode)
(delete-selection-mode 1)
(show-paren-mode 1)

(setq-default tab-width      4
              fill-column    80
              indent-tabs-mode      nil
              indicate-empty-lines  t
              require-final-newline t
              sentence-end-double-space nil
              save-place nil)

(setq frame-title-format '(buffer-file-name "%f" ("%b"))
      inhibit-startup-screen t
      inhibit-splash-screen t
      ediff-window-setup-function 'ediff-setup-windows-plain
      diff-switches "-u"
      ;; node / create-react-app dislikes lock files
      create-lockfiles nil
      make-backup-files nil
      vc-follow-symlinks t
      ring-bell-function 'ignore
      tramp-mode nil)

(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

(add-hook 'emacs-lisp-mode-hook
	  '(lambda ()
	     (local-set-key (kbd "RET") 'newline-and-indent)))

(add-to-list 'load-path (concat user-emacs-directory "elisp"))

(require 'fill-column-indicator)
(setq fci-rule-column 120)

(require 'my-functions)
(require 'my-org)

(use-package solarized-theme
  :ensure nil
  :init
  (setq solarized-scale-org-headlines t)
  :config
  (load-theme 'solarized-dark t))

(use-package doom-themes
  :ensure t
  :config
  (load-theme 'doom-one 'no-confirm)
  (doom-themes-visual-bell-config))

(use-package smart-mode-line
  :ensure t
  :hook ((after-init . sml/setup))
  :config
  (setq sml/theme 'dark))

(use-package diminish
  :ensure t
  :defer t)

(use-package flycheck
  :ensure t
  :diminish flycheck-mode
  :hook ((after-init . global-flycheck-mode)))

(use-package helm
  :ensure t
  :diminish helm-mode
  :init
  (setq history-length 100 ; determines file-name-history; see helm-ff-file-name-history-use-recentf
        helm-split-window-default-side 'right
        helm-find-files-ignore-thing-at-point t)
  :bind
  (("M-x"     . helm-M-x)
   ("M-["     . helm-projectile-find-file)
   ("M-S"     . helm-projectile-rg)
   ("<f2>"    . helm-for-files)
   ("M-f"     . helm-swoop)
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

(use-package projectile
  :ensure t
  :diminish projectile-mode
  :bind-keymap (("C-c p" . projectile-command-map))
  :init
  (setq projectile-enable-caching t
        projectile-indexing-method 'native
        projectile-hg-command "hg files -0 -I ."
        projectile-create-missing-test-files t)
  :config
  (projectile-mode)
  (--each '("target" "node_modules" ".gradle" ".clj-kondo")
    (add-to-list 'projectile-globally-ignored-directories it))
  (--each '("*-all.js")
    (add-to-list 'projectile-globally-ignored-files it))
  (--each '(".log" ".png" ".gif" ".jar")
    (add-to-list 'projectile-globally-ignored-file-suffixes it))
  (--each '("*.png" "*.jpg" "*.gif" "*.jar" "*.log" "*.pdf" "*.jasper")
    (add-to-list 'grep-find-ignored-files it)))

(use-package helm-projectile
  :ensure t
  :pin melpa ;; not released in a long time
  :init
  (setq projectile-completion-system 'helm
        helm-source-projectile-files-and-dired-list '(helm-source-projectile-files-list))
  :config
  (helm-projectile-on))


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

(use-package lispy
  :ensure t
  :pin melpa
  :diminish lispy-mode
  :defer t
  :bind (([remap lispy-move-beginning-of-line] . mwim-beginning-of-code-or-line)
         :map lispy-mode-map
         (("C-d" . my-delete-region-or-line))
	 ;; Don't overwrite cider binding
	 ("M-." . nil)
	 ("M-d" . lispy-delete)
	 ("M-e" . lispy-backward-kill-word)
	 ("M-r" . lispy-kill-word))
  :hook ((clojure-mode . lispy-mode)
         (emacs-lisp-mode . lispy-mode)
         (common-lisp-mode . lispy-mode)
         (scheme-mode . lispy-mode)
         (lisp-mode . lispy-mode))
  :init
  (setq lispy-compat '(cider)
        lispy-key-theme '(special parinfer c-digits))

  ;; https://github.com/abo-abo/lispy/pull/403
  ;; temporary to get accustom to lispy
  (advice-add 'delete-selection-pre-hook :around 'lispy--delsel-advice))

(use-package cider
  :ensure t
  :defer t
  :bind (("C-<return>" . my-clojure-format-buffer)
	 ("M-." . cider-find-var))
  :init
  (setq cider-repl-pop-to-buffer-on-connect nil
	cider-save-file-on-load t
        cider-repl-use-pretty-printing t)
  :config
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
    :config
    (defun my-clj-refactor-set-keybinding-hook ()
      (cljr-add-keybindings-with-prefix "C-c C-m"))
    (add-hook 'clojure-mode-hook 'my-clojure-before-save-hook)
    (add-hook 'clojure-mode-hook 'clj-refactor-mode)
    (add-hook 'clojure-mode-hook 'fci-mode)
    (add-hook 'clojure-mode-hook 'my-clj-refactor-set-keybinding-hook))
  (use-package flycheck-clj-kondo
    :ensure t))

(use-package helm-swoop
  :pin melpa
  :ensure t
  :defer t)

(use-package super-save
  :ensure t
  :diminish super-save-mode
  :config
  (super-save-mode))

(use-package auto-dim-other-buffers
  :ensure t
  :hook ((after-init . auto-dim-other-buffers-mode)))

(setq custom-file "~/.emacs.local")

(if (file-exists-p "~/.emacs.local")
    (load "~/.emacs.local"))
