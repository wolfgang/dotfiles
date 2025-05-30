(defun my-babel-call ()
  (interactive)
  (progn
    (let* ((context
	        (org-element-lineage
	         (org-element-context)
	         ;; Limit to supported contexts.
	         '(babel-call clock dynamic-block footnote-definition
			              footnote-reference inline-babel-call inline-src-block
			              inlinetask item keyword node-property paragraph
			              plain-list planning property-drawer radio-target
			              src-block statistics-cookie table table-cell table-row
			              timestamp)
	         t)) 
           (type (org-element-type context)))
      (if (or (eq type 'babel-call ) (eq type 'inline-babel-call))
          (progn
            (advice-remove 'org-babel-execute-src-block  'ob-async-org-babel-execute-src-block)
            (let ((info (org-babel-lob-get-info context)))
	          (when info (org-babel-execute-src-block nil info nil type)))
            (advice-add 'org-babel-execute-src-block :around 'ob-async-org-babel-execute-src-block))))))


(defun my-clojure-before-save-hook ()
  (add-hook 'before-save-hook 'my-clojure-format-buffer nil 'local))



(defun my-clojure-format-buffer ()
  (interactive)
  (let ((p (point)))
    (progn
      (cider-format-buffer)
      (clojure-sort-ns)
      (goto-char p))))

(defun my-delete-line-keep-column-position ()
  "Delete current line and keep point at current column."
  (interactive)
  (let ((column-index (current-column)))
    (kill-whole-line)
    (move-to-column column-index)))

(defun my-delete-region-or-line ()
  "Delete region if active or current line."
  (interactive)
  (if (use-region-p)
      (call-interactively 'kill-region)
    (call-interactively 'my-delete-line-keep-column-position)))

(defun my-rustic-mode-auto-save-hook ()
  "Enable auto-saving in rustic-mode buffers."
  (when buffer-file-name
    (setq-local compilation-ask-about-save nil)))

(defun my-consult-ripgrep (&optional dir initial)
  (interactive "P")
  (consult-ripgrep dir (ivy-thing-at-point)))

(fset 'my-org-daily-agenda
      (kmacro-lambda-form [f12 ?d ?l] 0 "%d"))

(fset 'my-org-focus-task
   (kmacro-lambda-form [f9 tab ?\C-x ?n ?s] 0 "%d"))

(defun my-gdscript-docs-browse-symbol-at-point (&optional force-online)
  "Open the API reference for the symbol at point in the browser eww.
If a page is already open, switch to its buffer. Use local docs if gdscripts-docs-local-path set. Use the universal prefix (C-u) to force browsing the online API."
  (interactive)

  (let* ((symbol-at-point (thing-at-point 'symbol t))
         (symbol (if symbol-at-point (downcase symbol-at-point) ""))
         (buffer (seq-find
                  (lambda (current-buffer)
                    (with-current-buffer current-buffer
                      (when (derived-mode-p 'eww-mode)
                        (string-suffix-p symbol (string-remove-suffix ".html" (plist-get eww-data :url)) t))))
                  (buffer-list))))
    (if buffer (pop-to-buffer-same-window buffer)
      (if (string= "" symbol)
          (message "No symbol at point or open API reference buffers.")
            (let ((file (concat (file-name-as-directory gdscript-docs-local-path) (file-name-as-directory "classes") "class_" symbol ".html")))
              (if (file-exists-p file)
                    (eww-browse-url (concat "file:///" file "#" symbol) t)
                (message "No local API help for \"%s\"." symbol)))))))


(fset 'my-magit-stage-all-no-confirm
   (kmacro-lambda-form [f6 ?S ?q] 0 "%d"))


(defun my-notify (body title)
  (if (eq system-type 'darwin)
      (alert body :title title)
    (notifications-notify :body body :title title ) ))


(defun my-denote-create-devlog ()
  (interactive)
  (let ((date-string (format-time-string "%Y-%m-%d") ))
    (denote (format "Devlog %s" date-string)
            '("devlog")
            nil nil nil
            'devlog)))

(defun my-insert-now ()
  "Insert string for the current time formatted like '2:34 PM'."
  (interactive)
  (insert (format-time-string "%Y-%m-%d %H:%M")))


(defun my-denote-zk ()
  "Insert a blank ZK PR Note."
  (interactive)
  (denote-silo-extras-select-silo-then-command
   (make-denote-zk-dir) 'denote--new-zk))


(defun make-denote-zk-dir ()
  (if (s-ends-with? "-zk" denote-directory)
      (expand-file-name denote-directory)
    (concat (expand-file-name denote-directory) "-zk")))

(defun denote--new-zk ()
  "Insert a blank ZK Note."
  (interactive)
  (denote--new-note '("zk")))

(defun denote--new-note (tags)
  "Insert a blank note with given (TAGS)."
  (let ((title (denote-title-prompt)))
    (denote title tags nil)))

(defun my-toggle-window-dedication ()
  "Toggles window dedication in the selected window."
  (interactive)
  (set-window-dedicated-p (selected-window)
                          (not (window-dedicated-p (selected-window)))))


(defun my-get-git-log (repo since)
  (let ((log (shell-command-to-string (format "cd ~/workspace/%s && git log --since=-\"%s\" %s" repo since "--format=format:\"%H;;;%s\""))))
      (map 'list (lambda (line)
                   (let* ((parts (split-string line ";;;"))
                          (hash (car parts))
                          (title (car (cdr parts))))
                     (format "[[https://gitlab.com/wolfgangd/%s/-/commit/%s][%s]]" repo hash title)))                
           (split-string log "\n"))))

(defun my-insert-git-log ()
  (interactive)
  (progn
    (insert "- Today's commits\n")
    (insert (mapconcat (lambda (e) (format "  - %s" e))
                       (my-get-git-log "steel-rain" "3 weeks" ) "\n"))
    (insert "\n"))  )

(provide 'my-functions)
