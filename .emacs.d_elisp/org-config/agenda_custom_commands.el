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

(setq inbox
      `(tags-todo ,inbox-match
		  (
		   (org-agenda-overriding-header "Inbox")
		   (org-agenda-skip-function
		    '(oh/agenda-skip :headline-if '(subtask)
		   )
                    ))))

(setq someday `(tags "+TODO=\"MAYBE\"" ((org-agenda-overriding-header "Someday/Maybe"))))

(setq available-tasks
      `(tags-todo "-INBOX/!+TODO"
                     ((org-agenda-overriding-header "Available Tasks")
                      (org-agenda-skip-function
                       '(oh/agenda-skip :headline-if '(project)
                                        :subtree-if '(inactive habit scheduled deadline)
                                        :subtree-if-restricted-and '(single-task)))
                      (org-agenda-sorting-strategy '(category-keep)))))

(setq active-projects
  `(tags-todo "/!"
      ((org-agenda-overriding-header  "Projects")
       (org-agenda-skip-function
	'(oh/agenda-skip :subtree-if '(non-project inactive habit)
	  :headline-if-unrestricted-and '(subproject)))
       (org-agenda-sorting-strategy '(category-keep)))))

(setq stuck-projects
      '(tags-todo "-CANCELLED/!-HOLD-WAITING"
                     ((org-agenda-overriding-header "Stuck Projects")
                      (org-agenda-skip-function
                       '(oh/agenda-skip :subtree-if '(inactive non-project non-stuck-project habit scheduled deadline))))))

(setq skip-used-timeslots
     '(org-agenda-skip-function '(org-agenda-skip-entry-if 'todo '("USED"))))

(setq org-agenda-custom-commands `(
                                   ("t" "Tasks" (,next-actions
                                                 ,available-tasks))
                                   ("d" "Today" ((agenda "" (,agenda-day-sort (org-agenda-span 'day) ,skip-used-timeslots))))

                                   ("p" "Active Projects" (,active-projects))
  				   ("#" "Stuck Projects"  (,stuck-projects))
				   ("i" "Inbox" (,inbox))
                                   ("y" "Someday/Maybe" (,someday))

                                   ("o" "Overview" ((agenda "" (,agenda-day-sort (org-agenda-span 'week) ,skip-used-timeslots))
                                                    ,next-actions
                                                    ,available-tasks
                                                    ,active-projects
						    ,stuck-projects                          
						    ,inbox
                                                    ,(recently-completed 2 "Recently Completed")
                                                    ,scratch
                                                    ,someday))
                                   
                                   ("e" "Completed" (,(recently-completed 365 "Completed Tasks")))
                                   ("k" "Knowledge Base" tags  "KB" ,(with-org-file "notebook.org"))
                                   ("b" "Notebook" tags  "NOTEBOOK&LEVEL>=2&LEVEL<=4" ,(with-org-file "notebook.org"))
                                   ))


      
