(setq gc-cons-threshold (* 100 1024 1024))
(setq gc-cons-percentage 0.6)


(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

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
      bookmark-set-fringe-mark nil
      ;; Use right alt keyt for system functions (umlauts, etc)
      ns-right-alternate-modifier 'none
      auto-revert-interval 3
      auto-revert-check-vc-info t
      ispell-silently-savep t)

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
 ("s-s" . swiper-isearch-backward)
 ("C-S-s" . swiper-isearch-thing-at-point)
 ("<end>" . mwim-end-of-code-or-line)
 ("<home>" . mwim-beginning-of-code-or-line)
 ("C-`" . other-frame)
 ("C-z n" . make-frame))


(define-key global-map [C-f2] #'term-toggle-term)

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


(defun flyspell-on-for-buffer-type ()
  (interactive)
  (if (and (not (symbol-value flyspell-mode)) (use-flyspell-here))
  (progn
	(if (derived-mode-p 'prog-mode)
	    (progn
	      (message "Flyspell on (code)")
	      (flyspell-prog-mode))
	  (progn
	    (message "Flyspell on (text)")
	    (flyspell-mode 1))))))

(defun use-flyspell-here ()
  (not (derived-mode-p 'magit-mode)))

(defun flyspell-toggle ()
  (interactive)
  (if (symbol-value flyspell-mode)
	  (progn
	    (message "Flyspell off")
	    (flyspell-mode -1))
	(flyspell-on-for-buffer-type)))

(add-hook 'find-file-hook 'flyspell-on-for-buffer-type)
;; (add-hook 'after-change-major-mode-hook 'flyspell-on-for-buffer-type)


(use-package ispell
  :init
  (setq ispell-program-name "hunspell")
  (setq ispell-dictionary "en_US,de_AT_frami")
  :config
  ;; ispell-set-spellchecker-params has to be called
  ;; before ispell-hunspell-add-multi-dic will work
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "en_US,de_AT_frami"))

(require 'fill-column-indicator)
(setq fci-rule-column 120)

(require 'linum-off)
(require 'my-functions)
(require 'my-org)

(global-linum-mode)

(setq custom-file "~/.emacs.local")
(if (file-exists-p custom-file) (load custom-file))



(use-package ivy :ensure t)
(use-package swiper :ensure t :after (ivy))

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
  (vertico-mode))


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

(use-package modus-themes
  :ensure t
  :disabled t
  :init
  (setq modus-themes-italic-constructs t
        modus-themes-bold-constructs nil
        modus-themes-region '(bg-only no-extend))
  :config
  (load-theme 'modus-vivendi :no-confirm))

(use-package ef-themes
  :ensure t
  :config
  (setq ef-themes-to-toggle '(ef-winter ef-summer))
  (mapc #'disable-theme custom-enabled-themes)
  (ef-themes-select 'ef-winter))

(use-package nord-theme
  :ensure t
  :disabled t
  :config
  (load-theme 'nord :no-confirm))

(use-package smart-mode-line
  :ensure t
  :hook ((after-init . sml/setup))
  :config
  (setq sml/theme 'respecful))

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
  (--each '("target" "node_modules" ".gradle" ".clj-kondo")
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
  :bind (("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-S" . my-consult-ripgrep)
         ("C-S-l" . consult-line)
         ("C-x C-r" . consult-recent-file)
         ("C-z p" . consult-project-buffer))
  :config
  (use-package consult-ag :ensure t))

(use-package embark
  :straight t
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
  :straight t
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
  :bind (:map js2-mode-map (("C-<return>" . prettier-js)))
  :config
  (setq prettier-js-args '()
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
                        (cider-repl-mode :select t :align below :size 0.4)
                        (godot-mode :select f :align below :size 0.3)))
  (shackle-mode 1))


(use-package terraform-mode
  :ensure t
  :defer t)

(use-package elfeed
  :ensure t
  :bind (("<C-f11>" . elfeed)))

(use-package ledger-mode
  :ensure t
  :defer t)

(use-package pocket-reader
  :ensure t
  :defer t
  :bind (("<C-f12>" . pocket-reader)))

(use-package s :ensure t)

(use-package multiple-cursors
  :ensure t
  :init
  (setq mc/always-run-for-all t)
  :bind
  (("C-c C-<" . mc/mark-all-like-this)
   ("C->" . mc/mark-next-like-this-symbol)
   ("C-<" . mc/mark-previous-like-this-symbo)))

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

(use-package iedit
  :ensure t
  :init
  (global-set-key (kbd "C-.") 'iedit-mode))

(use-package eglot
  :ensure t
  :defer t)

(use-package org-drill
  :ensure t
  :init
  (setq org-drill-save-buffers-after-drill-sessions-p nil))



;; Problems with tsc-dynlib on different platforms, disabled for now
(use-package tree-sitter
  :ensure nil
  :disabled t
  :config
  ;; activate tree-sitter on any buffer containing code for which it has a parser available
  (global-tree-sitter-mode)
  ;; you can easily see the difference tree-sitter-hl-mode makes for python, ts or tsx
  ;; by switching on and off
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :ensure nil
  :disabled t
  :after tree-sitter)

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

  :config
  (add-hook 'flycheck-mode-hook #'flycheck-angular-eslint-setup)
  
  :bind (:map tide-mode-map
              ("M-<return>" . tide-fix)
              ("C-c d" . tide-documentation-at-point))

  )



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



;; (add-to-list 'load-path "~/.emacs.d/elisp/emacs-gdscript-mode")
;; (require 'gdscript-mode)


(defun maybe-save () (when buffer-file-name (save-buffer)))

(defun lsp--gdscript-ignore-errors (original-function &rest args)
  "Ignore the error message resulting from Godot not replying to the `JSONRPC' request."
  (if (string-equal major-mode "gdscript-mode")
      (let ((json-data (nth 0 args)))
        (if (and (string= (gethash "jsonrpc" json-data "") "2.0")
                 (not (gethash "id" json-data nil))
                 (not (gethash "method" json-data nil)))
            nil ; (message "Method not found")
          (apply original-function args)))
    (apply original-function args)))


(use-package gdscript-mode
  :straight (gdscript-mode
             :type git
             :host github
             :repo "godotengine/emacs-gdscript-mode")
  :hook (gdscript-mode . eglot-ensure)
  :custom (gdscript-eglot-version 3)

  :init
  (setq gdscript-use-tab-indents t
        gdscript-gdformat-save-and-format nil
        gdscript-docs-use-eww nil)

  :config
  (advice-add 'gdscript-godot-run-project :before 'maybe-save)
  (advice-add 'gdscript-godot-run-current-scene :before 'maybe-save)
  (advice-add #'lsp--get-message-type :around #'lsp--gdscript-ignore-errors)

  (add-hook 'gdscript-mode-hook
            (lambda()
              (local-unset-key (kbd "<f6>"))
              (define-key gdscript-mode-map (kbd "C-<return>") 'gdscript-format-buffer)
              (define-key gdscript-mode-map (kbd "C-r") 'gdscript-godot-run-current-scene)
              (define-key gdscript-mode-map (kbd "C-b") 'gdscript-godot-run-project)
              (define-key gdscript-mode-map (kbd "C-c C-b w") 'my-gdscript-docs-browse-symbol-at-point))))

;; (use-package beframe
;;   :ensure t
;;   :init
;;   (defvar consult-buffer-sources)
;;   (declare-function consult--buffer-state "consult")

;;   (with-eval-after-load 'consult
;;     (defface beframe-buffer
;;       '((t :inherit font-lock-string-face))
;;       "Face for `consult' framed buffers.")

;;     (defvar beframe-consult-source
;;       `( :name     "Frame-specific buffers (current frame)"
;;          :narrow   ?F
;;          :category buffer
;;          :face     beframe-buffer
;;          :history  beframe-history
;;          :items    ,#'beframe-buffer-names
;;          :action   ,#'switch-to-buffer
;;          :state    ,#'consult--buffer-state))

;;     (add-to-list 'consult-buffer-sources 'beframe-consult-source)

;;     (define-key global-map (kbd "C-c b") beframe-prefix-map))

;;   :config
;;   (beframe-mode 1))


;; (use-package nameframe
;;   :ensure t
;;   :bind (("C-z f" . nameframe-switch-frame))
;;   :config
;;   (nameframe-projectile-mode t)
;;   )


(use-package denote
  :straight t
  :bind (("C-c n n" . denote)
         ("C-c n o" . denote-open-or-create)
         ("C-c n l" . denote-link)
         ("C-c n b" . denote-backlinks))
  :init
  (setq aw-scope 'frame)
  (add-hook 'dired-mode-hook #'denote-dired-mode))

(use-package ob-async
  :ensure t)


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

(straight-use-package
 '(eat :type git
       :host codeberg
       :repo "akib/emacs-eat"
       :files ("*.el" ("term" "term/*.el") "*.texi"
               "*.ti" ("terminfo/e" "terminfo/e/*")
               ("terminfo/65" "terminfo/65/*")
               ("integration" "integration/*")
               (:exclude ".dir-locals.el" "*-tests.el"))))
    
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

(use-package racket-mode :ensure t)

(use-package org-pomodoro :ensure t)



