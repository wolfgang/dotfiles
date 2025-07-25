;; -*- lexical-binding: t; -*-

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

(require 'cl)
(require 'notifications) ;; for (notifications-notify)

(global-auto-revert-mode 1)
(global-font-lock-mode 1)
(transient-mark-mode 1)
(savehist-mode 1)
(tool-bar-mode -1)
(column-number-mode)
(delete-selection-mode 1)
(show-paren-mode 1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(fset 'yes-or-no-p 'y-or-n-p)
(windmove-default-keybindings)
(electric-pair-mode)

(setq-default tab-width      4
              fill-column    80
              indent-tabs-mode      nil
              indicate-empty-lines  t
              require-final-newline t
              sentence-end-double-space nil
              save-place nil
              display-buffer-base-action '((display-buffer-reuse-window display-buffer-same-window)
                                           (reusable-frames . t))
              even-window-sizes nil)

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
      tramp-mode nil
      help-window-select t
      bookmark-set-fringe-mark nil
      ;; Use right alt keyt for system functions (umlauts, etc)
      ns-right-alternate-modifier 'none
      auto-revert-interval 3
      auto-revert-check-vc-info t
      switch-to-buffer-obey-display-actions t
      aw-scope 'frame)

(add-to-list 'display-buffer-alist
             '("\\*Org Agenda\\*"
               (display-buffer-reuse-window display-buffer-pop-up-window)
               (dedicated . t)))

(if (eq system-type 'darwin) (progn
                               (setq ns-function-modifier 'control)
                               (setq mac-command-modifier 'super)
                               (setq mac-right-command-modifier 'control)))

(global-unset-key "\C-z")


(bind-keys
 ("C-|" . split-window-horizontally)
 ("C-_" . split-window-vertically)
 ("C-c <left>"  . windmove-left)
 ("C-c <right>" . windmove-right)
 ("C-c <up>" . windmove-up)
 ("C-c <down>" . 'windmove-down)
 ("C-s" . swiper-isearch)
 ("C-r" . swiper-isearch-backward)
 ("C-S-s" . swiper-isearch-thing-at-point)
 ("<end>" . mwim-end-of-code-or-line)
 ("<home>" . mwim-beginning-of-code-or-line)
 ("C-`" . other-frame)
 ("C-z n" . make-frame)
 ("C-z m" . mc/mark-all-dwim)
 ("C-z t" . my-insert-now)
 ("C-z C-z" . my-babel-call)
 ("C-z o" . other-window-prefix))


(global-set-key [remap dabbrev-expand] 'hippie-expand)

(define-key global-map [C-f2] #'term-toggle-eshell)

(add-hook 'emacs-lisp-mode-hook
	      '(lambda ()
	         (local-set-key (kbd "RET") 'newline-and-indent)))

(add-to-list 'load-path (concat user-emacs-directory "elisp"))

(add-to-list 'default-frame-alist '(fullscreen . maximized))

(defun show-scratch-buffer (frame)
  "Display the scratch buffer in the newly created FRAME."
  (with-selected-frame frame
    (switch-to-buffer "*scratch*")))

(add-hook 'after-make-frame-functions 'show-scratch-buffer)

(require 'linum-off)
(require 'term-toggle)
(require 'my-functions)
(require 'my-org)

(global-linum-mode)
(winner-mode)

(setq custom-file "~/.emacs.local")
(if (file-exists-p custom-file) (load custom-file))



(use-package ivy :ensure t)
(use-package swiper :ensure t :after (ivy))

(use-package transient :ensure t)

(use-package vertico
  :ensure t
  :init
  (setq vertico-count 15
        vertico-resize nil)

  ;; https://github.com/minad/vertico#completion-at-point-and-completion-in-region
  (setq completion-in-region-function
        (lambda (&rest args)
          (apply (if vertico-mode
                     #'consult-completion-in-region
                   #'completion--in-region)
                 args)))

  (vertico-mode)
  (vertico-multiform-mode)
  ;; Reverse alpha short for denote to show newest entries first
  (setq vertico-multiform-commands
        '((denote-open-or-create (vertico-sort-function . (lambda (v) (reverse (vertico-sort-alpha v))))))))


(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless substring basic)))

(use-package marginalia
  :ensure t
  :bind (("M-A" . marginalia-cycle)
         :map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init
  ;; Must be in the :init section of use-package such that the mode gets
  ;; enabled right away. Note that this forces loading the package.
  (marginalia-mode))


(use-package recentf
  :ensure nil
  :init
  (setq recentf-max-saved-items 200)
  :config
  (recentf-mode 1))

(use-package smart-mode-line
  :ensure t
  :hook ((after-init . sml/setup))
  :config
  (setq sml/theme 'respecful))

(use-package modus-themes
  :ensure t
  :config
  (load-theme 'modus-operandi-tinted 'no-confirm ))

(use-package diminish
  :ensure t
  :defer t)

(use-package flycheck
  :ensure t
  :diminish flycheck-mode
  :hook ((after-init . global-flycheck-mode)))


(use-package dash :ensure t)

(use-package projectile
  :ensure t
  :diminish projectile-mode
  :bind-keymap (("C-c p" . projectile-command-map))
  :init
  (projectile-mode)
  (setq projectile-enable-caching t
        projectile-indexing-method 'native
        projectile-hg-command "hg files -0 -I ."
        projectile-create-missing-test-files t
        projectile-completion-system 'auto)
  :bind (("M-[" . projectile-find-file))
  :config
  (--each '("target" "node_modules" ".gradle" ".clj-kondo" "compiled")
    (add-to-list 'projectile-globally-ignored-directories it))
  (--each '("*-all.js")
    (add-to-list 'projectile-globally-ignored-files it))
  (--each '(".log" ".png" ".gif" ".jar")
    (add-to-list 'projectile-globally-ignored-file-suffixes it))
  (--each '("*.png" "*.jpg" "*.gif" "*.jar" "*.log" "*.pdf" "*.jasper")
    (add-to-list 'grep-find-ignored-files it))

  (defun update-frame-title-with-projectile-and-file ()
    "Rename the frame after switching Projectile projects."
    (let ((project-name (projectile-project-name)))
      (when project-name
        (setq frame-title-format
              (format "%s - %s"
                      (projectile-project-name)
                      (if (buffer-file-name)
                          (file-relative-name (buffer-file-name) (projectile-project-root))
                        "%b")))
        
        )))
  
  (add-hook 'projectile-after-switch-project-hook 'update-frame-title-with-projectile-and-file)
  (add-hook 'buffer-list-update-hook #'update-frame-title-with-projectile-and-file))


(use-package consult
  :ensure t
  :after (projectile)
  :init
  (setq consult-project-function (lambda (_) (projectile-project-root)))
  (setq consult-ripgrep-args
   "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /   --smart-case --no-heading --with-filename --line-number --search-zip")
  :bind (("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-S" . my-consult-ripgrep)
         ("C-S-l" . consult-line)
         ("C-x C-r" . consult-recent-file)
         ("C-z p" . consult-project-buffer))
  :config
  (use-package consult-ag :ensure t))

(use-package embark
  :ensure t
  :bind
  (("C-\\" . embark-act)
   ("C-;" . embark-dwim)
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'
  :init
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t        ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  ;; :hook
  ;; (embark-collect-mode . consult-preview-at-point-mode)
  )


(use-package magit
  :ensure t
  :bind (("<f6>" . magit-status)
         ("S-<f6>" . my-magit-stage-all-no-confirm)
         ("C-z r" . magit-list-repositories))
  :init
  (setq magit-commit-show-diff nil
        magit-save-repository-buffers 'dontask
        magit-repolist-columns '(("Name" 25 magit-repolist-column-ident nil)
                                 ("S" 5 magit-repolist-column-flag nil)
                                ("B<U" 3 magit-repolist-column-unpulled-from-upstream
                                 ((:right-align t)
                                  (:help-echo "Upstream changes not in branch")))
                                ("B>U" 3 magit-repolist-column-unpushed-to-upstream
                                 ((:right-align t)
                                  (:help-echo "Local changes not in upstream")))
                                ("Path" 99 magit-repolist-column-path nil)))
  :config
  (setq magit-no-confirm (append magit-no-confirm '(stage-all-changes))))

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
  :config
  (global-company-mode)
  ;; respect case when inserting into buffer, ignore when searching for candidates
  (setq company-dabbrev-downcase nil
        company-dabbrev-ignore-case 'yes
        company-idle-delay 0.3
        company-show-numbers t))

(use-package lispy
  :ensure t
  :diminish lispy-mode
  :defer t
  :bind (([remap lispy-move-beginning-of-line] . mwim-beginning-of-code-or-line)
         :map lispy-mode-map
         (("C-d" . my-delete-region-or-line)
          ("M-o" . nil)
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
         (lisp-mode . lispy-mode)
         (racket-mode . lispy-mode))
  :init
  (setq lispy-compat '(cider)
        lispy-key-theme '(special parinfer c-digits))
  (advice-add 'delete-selection-pre-hook :around 'lispy--delsel-advice)
  :config
  
  (add-to-list 'lispy-colon-no-space-regex '(racket-mode . "")))


(use-package cider
  :ensure t
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
    :ensure t))

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

(use-package smartparens
  :ensure t)

(use-package smartparens-config
  :ensure smartparens)

(use-package json-mode
  :ensure t
  :defer t)

(use-package xref-js2
  :ensure t)

(use-package js2-mode
  :ensure t
  :after xref-js2
  :mode "\\.js\\'"
  :hook ((js2-mode . smartparens-mode))
  :config
  ;; This binding is used by xref-js2
  (define-key js2-mode-map (kbd "M-.") nil)
  (add-hook 'js2-mode-hook (lambda ()
                             (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))
  :interpreter "node")

(use-package prettier-js
  :ensure t
  :init
  (setq pretter-js-show-errors nil)
  :hook ((rjsx-mode . prettier-js-mode)
         (js-ts-mode . prettier-js-mode)
         (json-mode . prettier-js-mode))
  :bind (:map js-ts-mode-map (("C-<return>" . prettier-js)))
  :config
  (setq prettier-js-args '()
        prettier-js-show-errors 'echo))

(use-package shackle
  :ensure t
  :config
  (setq shackle-rules '((magit-status-mode :align below :inhibit-window-quit t :select t :size 0.45)
                        (helpful-mode :select t :align below)
                        ("*lsp-help*" :select t :align below)
                        (embark-collect-mode :select t :align right)
                        ("Embark Actions" :select t :align right)
                        (occur-mode :select t :align right)
                        ("*Help*" :select t :align below)
                        (racket-describe-mode :select t :align below)
                        ("*cider-test-report*" :select t :align below)
                        ("*cider-error*"  :align below)
                        ("*cider-result*"  :align below :size 0.3)
                        ("*eshell*"  :align below :size 0.3)
                        ("*cargo-run*"  :align below :size 0.3)
                        ("*Flycheck errors*" :select t :align below)
                        (cider-repl-mode :select t :align below :size 0.4)
                        (racket-repl-mode :align below :size 0.3)
                        (godot-mode :align below :size 0.3)
                        ("*Org-Babel Error Output*" :align below :size 0.3)
                        ("*Warnings*" :align below :size 0.3)))
  (shackle-mode 1))


;; Problems with tsc-dynlib on different platforms, disabled for now
;; (use-package tree-sitter
;;   :ensure nil
;;   :disabled t
;;   :config
;;   ;; activate tree-sitter on any buffer containing code for which it has a parser available
;;   (global-tree-sitter-mode)
;;   ;; you can easily see the difference tree-sitter-hl-mode makes for python, ts or tsx
;;   ;; by switching on and off
;;   (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

;; (use-package tree-sitter-langs
;;   :ensure nil
;;   :disabled t
;;   :after tree-sitter)


(use-package treesit
  :mode (("\\.tsx\\'" . tsx-ts-mode))
  :preface
  (defun mp-setup-install-grammars ()
    "Install Tree-sitter grammars if they are absent."
    (interactive)
    (dolist (grammar
             '((css . ("https://github.com/tree-sitter/tree-sitter-css" "v0.20.0"))
               (html . ("https://github.com/tree-sitter/tree-sitter-html" "v0.20.1"))
               (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "v0.20.1" "src"))
               (json . ("https://github.com/tree-sitter/tree-sitter-json" "v0.20.2"))
               (python . ("https://github.com/tree-sitter/tree-sitter-python" "v0.20.4"))
               (toml "https://github.com/tree-sitter/tree-sitter-toml")
               (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "tsx/src"))
               (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "typescript/src"))
               (yaml . ("https://github.com/ikatyang/tree-sitter-yaml" "v0.5.0"))))
      (add-to-list 'treesit-language-source-alist grammar)
      ;; Only install `grammar' if we don't already have it
      ;; installed. However, if you want to *update* a grammar then
      ;; this obviously prevents that from happening.
      (unless (treesit-language-available-p (car grammar))
        (treesit-install-language-grammar (car grammar)))))

  ;; Optional, but recommended. Tree-sitter enabled major modes are
  ;; distinct from their ordinary counterparts.
  ;;
  ;; You can remap major modes with `major-mode-remap-alist'. Note
  ;; that this does *not* extend to hooks! Make sure you migrate them
  ;; also
  (dolist (mapping
           '((python-mode . python-ts-mode)
             (css-mode . css-ts-mode)
             (typescript-mode . typescript-ts-mode)
             (js2-mode . js-ts-mode)
             (bash-mode . bash-ts-mode)
             (css-mode . css-ts-mode)
             (json-mode . json-ts-mode)
             (js-json-mode . json-ts-mode)))
    (add-to-list 'major-mode-remap-alist mapping))
  :config
  (mp-setup-install-grammars)

  :interpreter "node")

(use-package rjsx-mode
  :ensure t
  :after xref-js2
  :bind (:map rjsx-mode-map
              ("C-d" . my-delete-region-or-line))
  :config
  (define-key js2-mode-map (kbd "M-.") nil)
  (add-hook 'rjsx-mode-hook (lambda ()
                              (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t))))





(use-package super-save
  :ensure t
  :diminish super-save-mode
  :config
  (setq super-save-auto-save-when-idle t)
  (setq auto-save-default nil)
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
        lsp-signature-doc-lines 3
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
        lsp-ui-doc-show-with-cursor nil
        lsp-ui-sideline-show-diagnostics nil
        lsp-ui-doc-enable nil)
  :bind (:map lsp-ui-mode-map
              ("M-j" . lsp-ui-imenu)
              ("M-?" . lsp-ui-peek-find-references))
  :commands
  lsp-ui-mode)

(use-package helpful
  :ensure t
  :bind (("C-<f1>" . helpful-at-point)
         ("C-h f" . helpful-function)))

(use-package elfeed
  :ensure t
  :bind (("<C-f11>" . elfeed)))

(use-package ledger-mode
  :ensure t
  :defer t)

(use-package s :ensure t)

(use-package multiple-cursors
  :ensure t
  :init
  (setq mc/always-run-for-all t)
  :bind
  (("C-c C-<" . mc/mark-all-like-this)
   ("C->" . mc/mark-next-like-this-symbol)
   ("C-<" . mc/mark-previous-like-this-symbo)))

(use-package js2-refactor
  :ensure t
  :defer t
  :config
  (js2r-add-keybindings-with-prefix "C-c C-m")
  :hook ((js2-mode . js2-refactor-mode)))


(use-package expand-region
  :ensure t
  :init
  (global-set-key (kbd "C-=") 'er/expand-region))

(use-package wgrep
  :ensure t)

(use-package crux
  :ensure t
  :bind (("C-c o" . crux-open-with)
         ("C-S-<return>" . crux-smart-open-line-above)
         ("S-<return>" . crux-smart-open-line)
         ("C-c u" . crux-view-url)
         ("C-c e" . crux-eval-and-replace)
         ("C-c D" . crux-delete-file-and-buffer)
         ("C-M-<down>" . crux-duplicate-current-line-or-region)
         ("C-S-M-<down>" . crux-duplicate-and-comment-current-line-or-region)
         ("C-S-r" . crux-rename-file-and-buffer)
         ("C-c t" . crux-visit-term-buffer)
         ("C-c j" . crux-top-join-line)
         ("M-E" . crux-kill-line-backwards)
         ("C-t" . crux-transpose-windows)))

(use-package discover-my-major
  :ensure t
  :bind (("C-h C-m" . discover-my-major)
         ("C-h M-m" . discover-my-mode)))

(use-package yaml-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
  (add-to-list 'auto-mode-alist '("\\.yaml\\'" . yaml-mode))
  :ensure t)

(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :after lispy
  :init
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  :bind (("C-z y" . yas-insert-snippet))
  :config
  ;; Lispy uses the tab key 
  (define-key yas-minor-mode-map (kbd "TAB") yas-maybe-expand)
  (define-key yas-minor-mode-map (kbd "<tab>") yas-maybe-expand)
  (yas-global-mode))

(use-package iedit
  :ensure t
  :init
  (global-set-key (kbd "C-.") 'iedit-mode))

(use-package org-drill
  :ensure t
  :init
  (setq org-drill-save-buffers-after-drill-sessions-p nil))

(defun setup-tide-mode ()
  (interactive)
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  (company-mode +1))


(defun flycheck-angular-eslint-setup ()
  (flycheck-add-next-checker 'typescript-tide '(warning . javascript-eslint))
  (setq-local flycheck-javascript-eslint-args
              '("--ext" ".ts"
                "--parser" "@typescript-eslint/parser"
                "--plugin" "angular"
                "--config" ".eslintrc.json"
                "--resolve-plugins-relative-to" "."))
  (setq-local flycheck-javascript-eslint-executable "eslint"))

(use-package tide
  :ensure t
  ;; :after (tree-sitter-langs)
  :init
  (setq tide-format-options '(:indentSize 2 :tabSize 2 :convertTabsToSpaces t)
        typescript-indent-level 2
        company-tooltip-align-annotations t)

  ;; For some reason this does not work in :config
  (add-hook 'before-save-hook 'tide-format-before-save)
  (add-hook 'typescript-mode-hook #'setup-tide-mode)
  (add-hook 'typescript-ts-mode-hook #'setup-tide-mode)

  :config
  (add-hook 'flycheck-mode-hook #'flycheck-angular-eslint-setup)
  
  :bind (:map tide-mode-map
              ("M-<return>" . tide-fix)
              ("C-c d" . tide-documentation-at-point)))



(use-package web-mode
  :ensure t
  :after (flycheck)
  :config
  ;; enable typescript - tslint checker
  (flycheck-add-mode 'typescript-tslint 'web-mode)
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.html\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.css\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.scss\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.ftl\\'" . web-mode))
  (add-hook 'web-mode-hook
            (lambda ()
              (when (string-equal "tsx" (file-name-extension buffer-file-name))
                (setup-tide-mode)))))



(use-package org-download
  :ensure t
  :init
  (setq org-download-method 'attach
        org-image-actual-width nil
        org-download-image-html-width 400))

(defun indent-region-advice (&rest ignored)
  (let ((deactivate deactivate-mark))
    (if (region-active-p)
        (indent-region (region-beginning) (region-end))
      (indent-region (line-beginning-position) (line-end-position)))
    (setq deactivate-mark deactivate)))

(use-package move-text
  :ensure t
  :config
  (global-set-key (kbd "M-<up>") 'move-text-up)
  (global-set-key (kbd "M-<down>") 'move-text-down)

  (advice-add 'move-text-up :after 'indent-region-advice)
  (advice-add 'move-text-down :after 'indent-region-advice))

(use-package dired-sidebar
  :ensure t
  :commands (dired-sidebar-toggle-sidebar)
  :init
  (setq dired-sidebar-subtree-line-prefix "-"
        dired-sidebar-should-follow-file t
        dired-sidebar-theme 'acii
        dired-sidebar-use-term-integration t
        dired-sidebar-use-custom-font t)
  :config
  (add-to-list 'linum-disabled-modes-list 'dired-sidebar-mode)
  :bind (("C-z s" . dired-sidebar-toggle-sidebar)))

(use-package denote
  :ensure t
  :bind (("C-c n n" . denote)
         ("C-c n o" . denote-open-or-create)
         ("C-c n l" . denote-link-or-create)
         ("C-c n h" . denote-org-link-to-heading)
         ("C-c n b" . denote-backlinks)
         ("C-c n d" . my-denote-create-devlog)
         ("C-c n j" . denote-journal-new-or-existing-entry)
         ("C-c n z" . my-denote-zk)
         ("C-c n s" . denote-silo-open-or-create))
  :init
  (setq denote-link-backlinks-display-buffer-action
        '((display-buffer-reuse-window
           display-buffer-in-side-window)
          (side . bottom)
          (slot . 99)
          (window-height . 0.4)
          (dedicated . t)
          (preserve-size . (t . t))))

  (setq denote-templates nil)
  (setq denote-prompts '(title keywords))
  (add-hook 'dired-mode-hook #'denote-dired-mode)
  (use-package denote-journal :ensure t)
  (use-package denote-silo :ensure t)
  (use-package denote-org :ensure t)
  (use-package consult-denote
  :ensure t
  :config
  (define-key global-map (kbd "C-c n f") #'consult-denote-find)
  (define-key global-map (kbd "C-c n g") #'consult-denote-grep)
  (consult-denote-mode 1)))


(use-package ob-async :ensure t)

(use-package ace-window
  :ensure t
  :init
  (setq aw-scope 'frame
        aw-dispatch-always t)
  :config
  (global-set-key (kbd "M-o") 'ace-window))

(use-package zoom-window
  :ensure t
  :init
  (setq zoom-window-mode-line-color "black")
  :bind (("C-z z" . zoom-window-zoom)))


(use-package moody
  :ensure t
  :config
  (setq x-underline-at-descent-line t)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode)
  (moody-replace-eldoc-minibuffer-message-function))

(use-package minions :ensure t
  :config
  (minions-mode 1))

(use-package eyebrowse :ensure t
  :init
  (setq eyebrowse-keymap-prefix (kbd "C-z C-w")
        eyebrowse-wrap-around t)
  :bind (("C-z ." . eyebrowse-switch-to-window-config)
         ("C-z 0" . eyebrowse-switch-to-window-config-0)
         ("C-z 1" . eyebrowse-switch-to-window-config-1)
         ("C-z 2" . eyebrowse-switch-to-window-config-2)
         ("C-z 3" . eyebrowse-switch-to-window-config-3)
         ("C-z 4" . eyebrowse-switch-to-window-config-4)
         ("C-z 5" . eyebrowse-switch-to-window-config-5)
         ("C-z 6" . eyebrowse-switch-to-window-config-6)
         ("C-z 7" . eyebrowse-switch-to-window-config-7)
         ("C-z 8" . eyebrowse-switch-to-window-config-8)
         ("C-z 9" . eyebrowse-switch-to-window-config-9))
  :config
  (global-set-key (kbd "<C-tab>") 'eyebrowse-next-window-config)
  (eyebrowse-mode 1))

(use-package racket-mode
  :ensure t
  :diminish racket-xp-mode
  :bind
  (:map racket-mode-map
        ("C-c r e" . racket-eval-last-sexp)
        ("C-c C-r" . racket-run))
  :config
  (add-to-list 'auto-mode-alist '("\\.rkt\\'" . racket-mode))
  (setq racket-show-functions '())
  (setq racket-xp-eldoc-level 'minimal)
  (add-hook 'racket-mode-hook 'racket-xp-mode)
  ;; electric-pair-mode breaks barf-to-point and adds newline when cloning sexp
  (add-hook 'racket-mode-hook (lambda () (electric-pair-mode 0))))

(use-package avy :ensure t
  :init
  (setq avy-timeout-seconds 10.0)
  :bind (("M-j" . avy-goto-char-timer)))

(use-package ibuffer
  :hook (ibuffer-mode . ibuffer-auto-mode)
  :defer t)

(use-package citar
  :ensure t
  :no-require
  :custom
  (org-cite-global-bibliography '("~/bib/references.bib"))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar)
  (citar-bibliography org-cite-global-bibliography))

(use-package pulsar
  :ensure t
  :config
  (pulsar-global-mode 1))

(use-package jinx
  :ensure t
  :init
  (setq jinx-languages "de_AT_frami,en_US")
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :config
  (global-jinx-mode))

(use-package ready-player
  :ensure t
  :config
  (ready-player-mode +1))

(use-package gptel
  :ensure t
  :config
  
  (gptel-make-ollama "Ollama"  
    :host "localhost:11434"    
    :stream t                  
    :models '(deepseek-r1:latest))
  (gptel-make-anthropic "Claude"
    :stream t
    :key claude-api-key)

  (gptel-make-tool
   :name "read_buffer"                  ; javascript-style snake_case name
   :function (lambda (buffer)           ; the function that will run
               (unless (buffer-live-p (get-buffer buffer))
                 (error "error: buffer %s is not live." buffer))
               (with-current-buffer  buffer
                 (buffer-substring-no-properties (point-min) (point-max))))
   :description "return the contents of an emacs buffer"
   :args (list '(:name "buffer"
                       :type string     ; :type value must be a symbol
                       :description "the name of the buffer whose contents are to be retrieved"))
   :category "emacs")

  (gptel-make-tool
   :name "create_file"                    ; javascript-style  snake_case name
   :function (lambda (path filename content)   ; the function that runs
               (let ((full-path (expand-file-name filename path)))
                 (with-temp-buffer
                   (insert content)
                   (write-file full-path))
                 (format "Created file %s in %s" filename path)))
   :description "Create a new file with the specified content"
   :args (list '(:name "path"             ; a list of argument specifications
	                   :type string
	                   :description "The directory where to create the file")
               '(:name "filename"
	                   :type string
	                   :description "The name of the file to create")
               '(:name "content"
	                   :type string
	                   :description "The content to write to the file"))
   :category "filesystem")                ; An arbitrary label for grouping
  
  (gptel-make-tool
   :name "overwrite_buffer"
   :description "Overwrite the contents of an Emacs buffer. Name of the buffer is given by the buffer parameter. The new content is given by the content parameter "
   :category "emacs"
   :args (list '(:name "buffer"
                       :type string
                       :description "The name of the buffer whose contents are to be overwritten")
               '(:name "content"
                       :type string
                       :description "The new buffer content"))
   :function (lambda (buffer content)
               (condition-case err
                   (with-current-buffer buffer
                     (progn
                       (erase-buffer)
                       (insert content)
                       (format "Successfully modified buffer %s with %d characters" 
                               buffer (length content))))
                 (error (format "Error modifying buffer %s: %s" buffer (error-message-string err))))))

  )
