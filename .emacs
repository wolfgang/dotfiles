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
(menu-bar-mode -1)
(fset 'yes-or-no-p 'y-or-n-p)
(windmove-default-keybindings)

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

(bind-keys
 ("C-|" . split-window-horizontally)
 ("C-_" . split-window-vertically)
 ("C-c <left>"  . windmove-left)
 ("C-c <right>" . windmove-right)
 ("C-c <up>" . windmove-up)
 ("C-c <down>" . 'windmove-down)
 ("C-s" . swiper-isearch))

(add-hook 'emacs-lisp-mode-hook
	      '(lambda ()
	         (local-set-key (kbd "RET") 'newline-and-indent)))

(add-to-list 'load-path (concat user-emacs-directory "elisp"))

(require 'fill-column-indicator)
(setq fci-rule-column 120)

(require 'my-functions)
(require 'my-org)

(use-package gruvbox-theme
  :ensure t
  :config
  (load-theme 'gruvbox-dark-medium t))

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
   ("M-f"     . helm-projectile-ag)
   ("<f2>"    . helm-for-files)
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
  :bind (("<f6>" . magit-status))
  :init
  (setq magit-save-repository-buffers 'dontask))

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
        company-idle-delay 0.3
        company-show-numbers t))

(use-package lispy
  :ensure t
  :pin melpa
  :diminish lispy-mode
  :defer t
  :bind (([remap lispy-move-beginning-of-line] . mwim-beginning-of-code-or-line)
         :map lispy-mode-map
         (("C-d" . my-delete-region-or-line)
	      ;; Don't overwrite cider binding
	      ("M-." . nil)
	      ("M-d" . lispy-delete)
          ("M-m" . lispy-mark-symbol)
          ("C-," . lispy-kill-at-point)
	      ("M-e" . lispy-backward-kill-word)
          ("C-M-," . lispy-mark)
	      ("M-r" . lispy-kill-word)))
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
  :ensure nil
  :defer t
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
  :bind (:map clojure-mode-map
              (("C-<return>" . my-clojure-format-buffer)
               ("M-." . cider-find-var)
               ("C-c C-d x" . cider-auto-test-mode)))
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


(use-package json-mode
  :ensure t
  :defer t)

(use-package js2-mode
  :ensure t
  :mode "\\.js\\'"
  :interpreter "node")

(use-package rjsx-mode
  :ensure t
  :mode "components\\/.*\\.js\\'"
  :bind (:map rjsx-mode-map
         ("C-d" . my-delete-region-or-line)))

(use-package prettier-js
  :ensure t
  :hook ((rjsx-mode . prettier-js-mode)
         (js2-mode . prettier-js-mode)
         (json-mode . prettier-js-mode)))

(use-package helm-swoop
  :pin melpa
  :ensure t
  :defer t)

(use-package super-save
  :ensure t
  :diminish super-save-mode
  :config
  (super-save-mode))

(use-package git-timemachine
  :ensure t
  :defer t)

(use-package mwim
  :ensure t
  :bind (([remap move-beginning-of-line] . mwim-beginning-of-code-or-line)
         ([remap move-end-of-line] . mwim-end-of-code-or-line)))

(use-package rustic
  :ensure t
  :defer t
  :bind (:map rustic-mode-map
              ("C-<return>" .  rustic-format-buffer)
              ("C-c C-c l" . flycheck-list-errors)
              ("C-c C-c a" . lsp-execute-code-action)
              ("C-c C-c r" . lsp-rename)
              ("C-c C-c q" . lsp-workspace-restart)
              ("C-c C-c s" . lsp-rust-analyzer-status)
              ("C-c C-c Q" . lsp-workspace-shutdown))
  :config
  (setq lsp-enable-symbol-highlighting nil)
  (add-hook 'rustic-mode-hook 'my-rustic-mode-auto-save-hook)
  ;; uncomment for less flashiness
  ;; (setq lsp-eldoc-hook nil)
  ;; (setq lsp-signature-auto-activate nil)
  (setq rustic-format-on-save nil))

(use-package lsp-mode
  :ensure t
  :defer t
  :init
  (setq lsp-keymap-prefix "C-c C-l"
        lsp-idle-delay 0.3
        lsp-modeline-code-actions-segments '(count name)
        lsp-rust-analyzer-cargo-watch-command "check"
        lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
        lsp-rust-analyzer-display-chaining-hints t
        lsp-rust-analyzer-display-closure-return-type-hints t
        lsp-eldoc-render-all nil
        lsp-rust-analyzer-server-display-inlay-hints nil
        lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil
        lsp-rust-analyzer-display-parameter-hints nil
        lsp-rust-analyzer-display-reborrow-hints nil)
  :commands
  (lsp lsp-deferred)
  :bind (:map lsp-mode-map
              ("M-<f1>" . lsp-describe-thing-at-point))
  :hook
  ((lsp-mode . lsp-ui-mode)
   (lsp-mode . lsp-enable-which-key-integration)))

(use-package lsp-ui
  :ensure t
  :defer t
  :init
  (setq lsp-ui-doc-enable t
        lsp-ui-peek-always-show t
        lsp-ui-sideline-show-code-actions nil
        lsp-ui-peek-show-directory nil
        lsp-ui-sideline-show-hover nil
        lsp-ui-doc-show-with-cursor nil)
  :bind (:map lsp-ui-mode-map
              ("M-j" . lsp-ui-imenu)
              ("M-?" . lsp-ui-peek-find-references))
  :commands
  lsp-ui-mode)

(use-package beacon
  :ensure t
  :config
  (beacon-mode 1))

(use-package helm-ag
  :ensure t
  :defer t)

(use-package helm-lsp
  :ensure t
  :defer t
  :commands
  helm-lsp-workspace-symbol)

(use-package keyfreq
  :ensure t
  :config
  (keyfreq-mode)
  (keyfreq-autosave-mode))

(use-package helpful
  :ensure t
  :bind (("C-<f1>" . helpful-at-point)
         ("C-h f" . helpful-function)))

(use-package shackle
  :ensure t
  :config
  (setq shackle-rules '((magit-status-mode :align 'below :inhibit-window-quit t :select t :size 0.45)
                        (magit-diff-mode :align 'below :inhibit-window-quit t :size 0.3)))
  (shackle-mode 1))

(setq custom-file "~/.emacs.local")

(if (file-exists-p "~/.emacs.local")
    (load "~/.emacs.local"))

