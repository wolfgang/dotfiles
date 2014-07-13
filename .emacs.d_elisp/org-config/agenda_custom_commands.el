(load "org-age-compare.el")
(load "util")

(defun age-sorted (Header Property &rest Direction)
  `(
    (org-agenda-overriding-header ,Header)
    (org-age-property ,Property) 
    (org-agenda-cmp-user-defined 'org-age-compare)
    (org-agenda-sorting-strategy ',Direction))
  )

(defun with-org-file (name)
  `((org-agenda-files '(,(org-file name)))))

(defun recently-completed (days header)
  (let ((match (format "TODO=\"DONE\"&CLOSED>=\"<-%dd>\"" days)))
	`(tags ,match ,(age-sorted header "CLOSED" 'user-defined-down))))

(defun scheduled-today ()
	`(tags "TODO=\"SCHD\"&SCHEDULED=\"<-0d>\""
	       ((org-agenda-overriding-header "Scheduled Today"))))

(setq agenda-day-sort '(org-agenda-sorting-strategy '(habit-down time-up priority-down todo-state-down)))

(setq next-actions `(tags-todo "TODO=\"NEXT\"" ((org-agenda-overriding-header "Next Actions" ))))
(setq scratch `(tags "+SCRATCH+LEVEL=1" ,(append '((org-agenda-overriding-header "Scratch")) (with-org-file "scratchpad.org"))))

(setq inbox-match  "+TODO=\"TODO\"-HABIT+INBOX")
(setq active-project-match "TODO=\"PROJ\"-INACTIVE")
(setq inactive-project-match "TODO=\"PROJ\"+INACTIVE")
(setq inbox-files `(org-agenda-files '(,(org-file "inbox.org") ,(org-file "inbox_r.org"))))

(setq embedded-inbox
      `(tags-todo ,inbox-match
		  (
		   (org-agenda-overriding-header "Inbox")
		   (org-agenda-skip-function
		    '(oh/agenda-skip :headline-if '(subtask)
		   )
		  ))))

(setq available-tasks
      `(tags-todo "-INBOX/!+TODO"
                     ((org-agenda-overriding-header "Available Tasks")
                      (org-agenda-skip-function
                       '(oh/agenda-skip :headline-if '(project)
                                        :subtree-if '(inactive habit scheduled deadline)
;                                        :subtree-if-unrestricted-and '(subtask)
                                        :subtree-if-restricted-and '(single-task)))
                      (org-agenda-sorting-strategy '(category-keep)))))

(setq active-projects
  `(tags-todo "/!"
      ((org-agenda-overriding-header  "------------------------------------------------\nProjects")
       (org-agenda-skip-function
	'(oh/agenda-skip :subtree-if '(non-project inactive habit)
	  :headline-if-unrestricted-and '(subproject)))
;	  :headline-if-restricted-and '(top-project)))
	(org-agenda-sorting-strategy '(category-keep)))))

(setq active-projects-today
      `(tags-todo "/!"
                  ((org-agenda-overriding-header  "------------------------------------------------\nProjects")
                   (org-agenda-skip-function
                    '(oh/agenda-skip :subtree-if '(non-project inactive habit)
                                     :headline-if-unrestricted-and '(subproject)))
                                        ;	  :headline-if-restricted-and '(top-project)))
                   (org-agenda-sorting-strategy '(category-keep)))))

(setq stuck-projects
      '(tags-todo "-CANCELLED/!-HOLD-WAITING"
                     ((org-agenda-overriding-header "Stuck Projects")
                      (org-agenda-skip-function
                       '(oh/agenda-skip :subtree-if '(inactive non-project non-stuck-project habit scheduled deadline))))))
(setq tasks-with-deadline
      `(tags-todo "-INBOX/!-MAYBE-DONE"
                  ((org-agenda-overriding-header "Deadlines")
                   (org-agenda-skip-function
                    '(oh/agenda-skip :headline-if '(not-deadline)))
                   (org-agenda-sorting-strategy '(deadline-up)))))
                                     

(setq skip-used-timeslots
     '(org-agenda-skip-function '(org-agenda-skip-entry-if 'todo '("USED"))))

(setq org-agenda-custom-commands `(,(append '("n" "Next Actions") next-actions)
				   ("." "Scheduled" tags "TODO=\"SCHD\"")
				   ("y" "Someday/Maybe" tags "TODO=\"MAYBE\"")
				   ,(append '("p" "Active Projects") active-projects)
  				   ,(append '("#" "Stuck Projects") stuck-projects)
				   ,(append '("i" "Inbox") embedded-inbox)
				   ("k" "Knowledge Base" tags  "KB" ,(with-org-file "notebook.org"))
				   ("b" "Notebook" tags  "NOTEBOOK&LEVEL>=2&LEVEL<=4" ,(with-org-file "notebook.org"))
				   
				   ("o" "Overview" ((agenda "" (,agenda-day-sort (org-agenda-span 'week) ,skip-used-timeslots))
						    ,active-projects
						    ,next-actions
						    ,stuck-projects
						    ,available-tasks
						    ,embedded-inbox
						    ,(recently-completed 2 "Recently Completed")
						    ,scratch
				    ))
				   ("d" "Today" ((agenda "" (,agenda-day-sort (org-agenda-span 'day) ,skip-used-timeslots))
                                                 ))

                                   ("t" "Tasks" (
                                                 ,next-actions
                                                 ,available-tasks
                                                 ))
                                   ("e" "Completed" (,(recently-completed 365 "Completed Tasks")))
                                   ))


      
