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
      bookmark-set-fringe-mark nil)

(if (eq system-type 'darwin) (setq mac-command-modifier 'control))

(bind-keys
 ("C-|" . split-window-horizontally)
 ("C-_" . split-window-vertically)
 ("C-c <left>"  . windmove-left)
 ("C-c <right>" . windmove-right)
 ("C-c <up>" . windmove-up)
 ("C-c <down>" . 'windmove-down)
 ("C-s" . swiper-isearch)
 ("C-S-s" . swiper-isearch-thing-at-point)
 ("C-z" . undo)
 ("C-`" . other-frame))

(add-hook 'emacs-lisp-mode-hook
	      '(lambda ()
	         (local-set-key (kbd "RET") 'newline-and-indent)))

(add-to-list 'load-path (concat user-emacs-directory "elisp"))

(require 'fill-column-indicator)
(setq fci-rule-column 120)

(require 'linum-off)
(require 'my-functions)
(require 'my-org)

(global-linum-mode)

(setq custom-file "~/.emacs.local")
(if (file-exists-p custom-file) (load custom-file))

(global-unset-key "\C-z")


;; Ensure availability of ivy-thing-at-point
(use-package ivy)

(use-package vertico
  :ensure t
  :init
  (setq vertico-count 20
        vertico-resize t )

  ;; Don't reverse results in searches
  (setq vertico-multiform-categories
        '((consult-grep (:not reverse))))
  (vertico-mode)
  (vertico-multiform-mode)
  (vertico-reverse-mode))


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
  :defer t
  :init
  (setq recentf-max-saved-items 200)
  :config
  (recentf-mode 1))

(use-package modus-themes
  :ensure nil
  :disabled t
  :init
  (setq modus-themes-italic-constructs t
        modus-themes-bold-constructs nil
        modus-themes-region '(bg-only no-extend))
  (modus-themes-load-themes)
  :config
  (modus-themes-load-vivendi))

(use-package ef-themes
  :ensure t
  :config
  (setq ef-themes-to-toggle '(ef-duo-dark ef-duo-light))
  (mapc #'disable-theme custom-enabled-themes)
  (ef-themes-select 'ef-duo-dark))

(use-package smart-mode-line
  :ensure t
  :hook ((after-init . sml/setup))
  :config
  (setq sml/theme 'respetful))

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
  (setq projectile-enable-caching t
        projectile-indexing-method 'native
        projectile-hg-command "hg files -0 -I ."
        projectile-create-missing-test-files t
        projectile-completion-system 'auto)
  :bind (("M-[" . projectile-find-file))
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

(use-package consult
  :ensure t
  :after (projectile)
  :init
  (setq consult-project-function (lambda (_) (projectile-project-root)))
  :bind (("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-S" . my-consult-ripgrep)
         ("C-x C-r" . consult-recent-file))
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
  :bind (("<f6>" . magit-status))
  :init
  (setq magit-commit-show-diff nil
        magit-save-repository-buffers 'dontask))

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

(use-package rjsx-mode
  :ensure t
  :after xref-js2
  :bind (:map rjsx-mode-map
              ("C-d" . my-delete-region-or-line))
  :config
  (define-key js2-mode-map (kbd "M-.") nil)
  (add-hook 'rjsx-mode-hook (lambda ()
                              (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t))))


(use-package prettier-js
  :ensure t
  :init
  (setq pretter-js-show-errors nil)
  :hook ((rjsx-mode . prettier-js-mode)
         (js2-mode . prettier-js-mode)
         (json-mode . prettier-js-mode))
  :config
  (setq prettier-js-args '("--plugin" "@trivago/prettier-plugin-sort-imports")
        prettier-js-show-errors 'echo))


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
   (lsp-mode . lsp-enable-which-key-integration)
   ;; (gdscript-mode . lsp)
   ))

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
  (setq shackle-rules '((magit-status-mode :align below :inhibit-window-quit t :select t :size 0.45)
                        (helpful-mode :select t :align below)
                        ("*lsp-help*" :select t :align below)
                        (embark-collect-mode :select t :align right)
                        ("Embark Actions" :select t :align right)
                        ("*Help*" :select t :align below)
                        ("*cider-test-report*" :select t :align below)
                        ("*cider-error*"  :align below)
                        ("*cider-result*"  :align below :size 0.3)
                        ("*Flycheck errors*" :select t :align below)
                        (cider-repl-mode :select t :align below :size 0.4)))
  (shackle-mode 1))

(use-package terraform-mode
  :ensure t)

(use-package elfeed
  :ensure t
  :bind (("<C-f11>" . elfeed)))

(use-package ledger-mode
  :ensure t)

(use-package pocket-reader
  :ensure t
  :bind (("<C-f12>" . pocket-reader)))

(use-package s :ensure t)

(use-package multiple-cursors
  :ensure t
  :bind
  (("C-c C-<" . mc/mark-all-like-this)
   ("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)))

(use-package yasnippet :ensure t)

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

(use-package paradox
  :ensure t
  :defer t
  :init
  (setq paradox-display-star-count nil))

(use-package crux
  :ensure t
  :pin melpa
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
         ("C-c i" . crux-ispell-word-then-abbrev)
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
  :init
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  :config
  (yas-global-mode))

(add-to-list 'load-path "~/.emacs.d/elisp/emacs-gdscript-mode")
(require 'gdscript-mode)

(defun maybe-save () (when buffer-file-name (save-buffer)))

(advice-add 'gdscript-godot-run-project :before 'maybe-save)
(advice-add 'gdscript-godot-run-current-scene :before 'maybe-save)

(add-hook 'gdscript-mode-hook
          (lambda()
            (eglot-ensure)
            (local-unset-key (kbd "<f6>"))
            (define-key gdscript-mode-map (kbd "C-<return>") 'gdscript-format-buffer)
            (define-key gdscript-mode-map (kbd "C-r") 'gdscript-godot-run-current-scene)
            (define-key gdscript-mode-map (kbd "C-b") 'gdscript-godot-run-project)
            (define-key gdscript-mode-map (kbd "C-c C-b w") 'my-gdscript-docs-browse-symbol-at-point)))
(setq gdscript-use-tab-indents t
      gdscript-gdformat-save-and-format nil
      gdscript-docs-use-eww nil)

(define-key global-map [C-f2] #'term-toggle-term)

(use-package eglot :ensure t)


