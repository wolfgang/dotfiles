
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(add-to-list 'load-path (file-name-directory load-file-name))

;(run-at-time "0:00" 120 'org-save-all-org-buffers)

(load "editor_settings.el")
(load "setup_directories.el")
(load "key_bindings.el")
(load "todo_keywords.el")
(load "capture_templates.el")
(load "agenda_custom_commands.el")
(load "alert-config.el")
(load "refile.el")
;; (load "org-pomodoro-config.el")

(require 'org-helpers)

(org-clock-persistence-insinuate)

(setq org-refile-targets '((org-agenda-files :maxlevel . 5)))
(setq org-agenda-remove-tags t)
(setq org-agenda-confirm-kill 10)
(setq org-startup-indented t)
(setq org-startup-folded 'overview)
(setq org-use-fast-todo-selection t)
(setq org-log-done 'time)
(setq org-clock-persist 'history)
(setq org-clock-into-drawer t)
(setq org-log-into-drawer t)
(setq org-cycle-separator-lines 0)
(setq org-agenda-compact-blocks t)
(setq org-duration-format 'h:mm)

(setq org-blank-before-new-entry (quote ((heading) 
					 (plain-list-item . auto))))

(setq org-global-properties '(("Effort_ALL" . "0:05 0:15 0:30 0:45 1:00 1:30 2:00 2:30 3:00 3:30 0:00")))

(setq org-columns-default-format "%70ITEM(Task) %8Effort(Effort){:} %8CLOCKSUM(Clock) %22CLOSED")
(setq org-agenda-overriding-columns-format org-columns-default-format)
(setq org-tags-exclude-from-inheritance '("PROJECT"))
(setq org-tag-alist nil)

(setq org-habit-graph-column 40)
(setq org-modules (cons 'org-habit org-modules))
(setq org-habit-show-all-today t)
(setq org-habit-following-days 1)

(setf (nth 4 org-emphasis-regexp-components) 100)

(setq org-stuck-projects '("TODO=\"PROJ\"-INACTIVE" ("TODO" "NEXT" "SCHD") nil ""))

(setq org-created-timestamp-max-level 99999)
(setq  org-created-timestamp-for-headings nil)

(setq safe-local-variable-values '((org-created-timestamp-for-headings . t)
				   (org-created-timestamp-max-level . 0) 
				   (org-created-timestamp-max-level . 1) 
				   (org-created-timestamp-max-level . 2) 
				   (org-created-timestamp-max-level . 3) 
				   (org-created-timestamp-max-level . 4) 
				   (org-created-timestamp-max-level . 5) 
				   (org-created-timestamp-max-level . 6) 
				   (org-created-timestamp-max-level . 7) 
				   (org-created-timestamp-max-level . 8) 
				   (org-created-timestamp-max-level . 9) 
				   (org-created-timestamp-max-level . 10)))

(setq org-agenda-scheduled-leaders '("" "Sched.%2dx: "))
(setq org-agenda-deadline-leaders '("" "In %3d d.: " "%2d d. ago: "))

(add-to-list 'exec-path "C:/Program Files (x86)/Aspell/bin/")
(setq ispell-program-name "aspell")
(setq ispell-dictionary "american")

(setq org-sort-agenda-notime-is-late t)

(defun custom-org-agenda-mode-defaults ()
  (org-defkey org-agenda-mode-map "W" 'oh/agenda-remove-restriction)
  (org-defkey org-agenda-mode-map "N" 'oh/agenda-restrict-to-subtree)
  (org-defkey org-agenda-mode-map "P" 'oh/agenda-restrict-to-project)
  (org-defkey org-agenda-mode-map "q" 'bury-buffer))

(add-hook 'org-agenda-mode-hook 'custom-org-agenda-mode-defaults 'append)


(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-allow-creating-parent-nodes (quote confirm))
(setq org-completion-use-ido nil)
(setq org-indirect-buffer-display 'current-window)

(setq org-agenda-prefix-format
      '((agenda . " %i %-16:c%?-16t% s")
       (timeline . "  % s")
       (todo . " %i %-16:c")
       (tags . " %i %-16:c")
       (search . " %i %-16:c")))

(setq org-deadline-warning-days 7)


(defun wd/verify-refile-target ()
  (let ((todo (org-get-todo-state )))
    (and
     (eq nil (string-match-p (regexp-quote "notebook.org") (buffer-file-name)))
     (or (eq nil todo) (equal "PROJ" todo)))))

(setq org-refile-target-verify-function 'wd/verify-refile-target)

